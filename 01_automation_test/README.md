


## Steps I performed to set up a simple apache server, hosting a static file.

* Install Virtualbox - If not already installed [Get it here](https://www.virtualbox.org/wiki/Downloads)

* Install Vagrant 
```
brew install vagrant
```
* Initialise Vagrant
```
vagrant init hashicorp/bionic64
```
* Use the Box(select option 2)
```
vagrant box add hashicorp/bionic64
```
* Start the VM
```
vagrant up
```

## Whoever reads this. Do the following
* Change to the 01_automation_test directory
* Install Virtualbox - If not already installed [Get it here](https://www.virtualbox.org/wiki/Downloads)

* Install Vagrant 
```
brew install vagrant
```
* Start the VM
* Go to this url: [here](http:127.0.0.1:4555)