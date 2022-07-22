import os
import boto3
from datetime import datetime

######################
## INIT
######################
ec2 = boto3.client('ec2')
ssm = boto3.client('ssm')
AMI_NAMES = ["Admin", "Worker"]
ENVS = ["prod", "qa"]
COMPONENTS = [os.getenv('ADMIN_AMI_SSM_NAME'), os.getenv('WORKER_AMI_SSM_NAME')]

######################
## FUNCTIONS
######################
def deregister_image(image):
    print(f"Deregistering AMI: {image['ImageID']}")
    ec2.deregister_image(ImageId=image["ImageID"])
    for snap_id in image["SnapshotIds"]:
        ec2.delete_snapshot(SnapshotId=snap_id)
    print(f"AMI with id {image['ImageID']} was successfully deregistered")


######################
## MAIN
######################
def main():
    res = ec2.describe_images(
        Filters=[{
            'Name': 'tag:Name',
            'Values': AMI_NAMES
        }],
    )['Images']
    
    images = [ 
        {
            "CreationTime": datetime.strptime(image['CreationDate'], '%Y-%m-%dT%H:%M:%S.000Z').timestamp(), 
            "ImageID": image['ImageId'], 
            "SnapshotIds": [ device['Ebs']['SnapshotId'] for device in image['BlockDeviceMappings'] if 'Ebs' in device.keys() ]
        } 
        for image in res
    ]
    
    LT = ec2.describe_launch_templates(
        Filters=[{
            'Name': 'tag:Project',
            'Values': ['DD']
        }],
    )['LaunchTemplates']
    
    used_amis = set()
    for template in LT:
        used_amis.add(ec2.describe_launch_template_versions(
            LaunchTemplateId=template['LaunchTemplateId'],
            Versions = [f"{template['LatestVersionNumber']}"]
        )['LaunchTemplateVersions'][0]['LaunchTemplateData']['ImageId'])

    if len(used_amis) != 0: print(f"Images which are still in use : {used_amis}")
    [deregister_image(image) for image in images if image["ImageID"] not in used_amis]

    ssm.delete_parameters(
        Names=[ f"{c}-{e}" for c in COMPONENTS for e in ENVS ]
    )

    return 0


if __name__ == "__main__":
    main()
