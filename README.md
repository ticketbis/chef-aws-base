# aws-base

'aws-base' is the base cookbook used by another AWS related cookbooks to install
the required gem in order to work with AWS. It also provides some useful functions
to work with AWS API.

## LWRPs

### credentials

Used to establish default credentials and region. It establishes the passed values in node
attributes and they are used by AWS LWRPs.

#### Parameters

* region: Amazon region to use
* access_key_id: the access key to use
* secret_access_key: the secret to use
