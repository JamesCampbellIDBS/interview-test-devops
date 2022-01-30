import boto3
import botocore
import threading
import logging
import datetime
import os
from botocore.exceptions import ClientError as Error
logger = logging.getLogger('share_rds_backups')
logger.setLevel(logging.INFO)
prefix = os.environ['DB_PREFIX']


# Getting all manual snapshots in the region specified
def list_snapshots_in_region(rds):
    iterator = rds.get_paginator('describe_db_snapshots').paginate(SnapshotType='manual')
    return sum([page['DBSnapshots'] for page in iterator], [])


# Matching snapshot_id with a defined prefix
def suitable_snapshot(snapshot_id, prefix):
    expected_prefix = f'msnapshot-{prefix}'
    return snapshot_id.startswith(expected_prefix)


def snapshots_in_region(region_client, customer_name):
    expected_prefix = 'msnapshot-' + customer_name.lower()
    iterator = region_client.get_paginator('describe_db_snapshots').paginate(SnapshotType='manual',
                                                                             DBInstanceIdentifier=customer_name.lower())
    snapshots = sum([page['DBSnapshots'] for page in iterator], [])
    customer_snapshots = [s for s in snapshots if s['DBSnapshotIdentifier'].startswith(expected_prefix)]
    return customer_snapshots


def copy_single_snapshot(snapshot, rds_copy_region, current_region, copy_region, deployment_name):
    sns_client = boto3.client('sns')
    try:
        copy_args = {
            "SourceDBSnapshotIdentifier": snapshot['DBSnapshotArn'],
            "TargetDBSnapshotIdentifier": snapshot['DBSnapshotIdentifier'],
        }
        rds_copy_region.copy_db_snapshot(**copy_args)
        logger.info(f"Copying snapshot {snapshot['DBSnapshotArn']} from {current_region} to {copy_region} region")
    except Error as e:
        error_code = e.response['Error']['Code']
        if error_code == 'DBSnapshotAlreadyExists':
            logger.info(f"Snapshot {snapshot['DBSnapshotIdentifier']} already exists in {copy_region}. "
                        f"Skipping copying..")
        else:
            logger.info(e, exc_info=True)
            sns_client.publish(TopicArn=os.environ['SNS_ARN'],
                               Subject=f"ALERT: {deployment_name} RDS Snapshot hasn't been copied",
                               Message=f"While copying the snapshot {snapshot['DBSnapshotArn']} to another region, "
                                       f"the following exception occurred: {e}")


def share_snapshot(rds_curr_region, rds_copy_region, deployment_name, current_region, copy_region, engine):
    logger.info('Checking for snapshots to copy...')
    curr_reg_snaps = snapshots_in_region(rds_curr_region, deployment_name)
    copy_reg_snaps = snapshots_in_region(rds_copy_region, deployment_name)
    for snapshot in curr_reg_snaps:
        # Snapshop will not be copied to region if already present
        if snapshot not in copy_reg_snaps and snapshot['Status'] == 'available':
            copy_single_snapshot(snapshot, rds_copy_region, current_region, copy_region, deployment_name)


def share_rds_backups(region):
    rds = boto3.client('rds', region)
    sns_client = boto3.client('sns', region)
    instances = rds.describe_db_instances().get('DBInstances', [])
    # setting a bunch of different data for each database found
    for instance in instances:
        instance_name = instance['DBInstanceIdentifier']
        instance_arn = instance['DBInstanceArn']
        deployment_name = instance_name.replace("dhostedewbdb", "")
        engine = instance['Engine']

        # Get copy region and retention time from tags.
        tags = rds.list_tags_for_resource(ResourceName=instance_arn)["TagList"]
        shared_backup_region = get_value_from_tag_list(tags, "copy_region")
        if shared_backup_region:
            rds_copy_region = boto3.client('rds', shared_backup_region)
            share_snapshot(rds, rds_copy_region, deployment_name, region, shared_backup_region, engine)


# Going to use this to get a copy region tag.
def get_value_from_tag_list(tag_list, key):
    for tag in tag_list:
        if tag.get("Key") == key:
            return tag.get("Value")
    return False


# This code assumes that RDS instances have a tag called 'copy_region', which is set to a predetermined region,
# for snapshots to be copied to.
def lambda_handler(event, context):
    rds = boto3.client('rds')
    regions = rds.describe_source_regions()
    region_dict = regions.get('SourceRegions')
    region_list = []
    threads = []
    # getting currently available RDS Regions. Better that hard coding a list.
    for r in region_dict:
        if r['Status'] == 'available':
            region_list.append(r['RegionName'])

    for region in region_list:
        # This threading, will ensure that the Lambda will execute backups in all regions in parallel, as opposed to the
        # standard for region, which would be sequentially. Running sequentially runs a risk of Lambda timeouts.
        thread = threading.Thread(name='Snapshot-Share', target=share_rds_backups, args=(region,))
        threads.append(thread)

    for thread in threads:
        thread.start()

    for thread in threads:
        thread.join()


if __name__ == "__main__":
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)
    formatter = logging.Formatter('[%(levelname)s]\t%(asctime)s\t%(name)s\t%(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    lambda_handler({}, None)
