import boto3
import threading
import logging
import datetime
import os
from botocore.exceptions import ClientError as Error

logger = logging.getLogger('take_rds_backups')
logger.setLevel(logging.INFO)


# Shared functions
def take_rds_backups(region):
    rds = boto3.client('rds', region)
    sns_client = boto3.client('sns')
    instances = rds.describe_db_instances().get('DBInstances', [])

    for instance in instances:
        instance_name = instances['DBInstanceIdentifier']
        # Only getting databases with specific naming convention. Could consider using tags to do this too.
        if (instance_name.startswith('hostedewb')
                and instance['DBInstanceStatus'] == 'available'):
            date = datetime.datetime.now()
            timestamp = date.strftime("%Y-%m-%d")
            snapshot_id = f'msnapshot-{instance_name}-{timestamp}'

            # Good practice to use a try except here, as there may be a reason why it can't be created.
            # Such as an AWS resource limit
            try:
                rds.create_db_snapshot(DBSnapshotIdentifier=snapshot_id, DBInstanceIdentifier=instance_name)
                print(f'Creating a new snapshot from {instance_name} instance in {region}...')
            except Error as e:
                if e.response['Error']['Code'] == 'DBSnapshotAlreadyExists':
                    print(f'DB snapshot {snapshot_id} for {instance_name} already exists, continuing...')
                else:
                    # As this is about backing up statefully data, people need to be informed.
                    # Not just assumed the cloudwatch logs are monitored.
                    sns_client.publish(TopicArn=os.environ['SNS_ARN'],
                                       Subject=f'ALERT: {instance_name} RDS snapshot failed to create',
                                       Message=f'While attempting to create a new snapshot {snapshot_id}, '
                                               f'the following exception occurred: {e}')

        elif instance['DBInstanceStatus'] != 'available' and instance_name.startswith('hostedewbdb'):
            print(f"Not creating snapshot for RDS instance: {instance_name}, "
                  f"instance status: {instance['DBInstanceStatus']}")


def lambda_handler(event, context):
    # Need to create a client too, as I need the region list before threading.
    client = boto3.client('rds')
    regions = client.describe_source_regions()
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
        thread = threading.Thread(name='Snapshot-Share', target=take_rds_backups, args=(region,))
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
