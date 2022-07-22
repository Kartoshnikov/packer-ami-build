import boto3
import argparse as argp

######################
## INIT
######################
ec2 = boto3.client('ec2')

######################
## FUNCTIONS
######################
def args_parser():
    a_parser = argp.ArgumentParser(description='Clean up DD AMIs')
    a_parser.add_argument(
        '-i',
        metavar='<ami id>',
        help='AMI ID as specified in HashiCorp Packer config.'
    )
    args = a_parser.parse_args()
    cmd_line_args = {'ami_id': args.i}
    return cmd_line_args
    
def deregister_image(image):
    print(f"Deregistering AMI: {image['ImageID']}")
    ec2.deregister_image(ImageId=image["ImageID"])
    for snap_id in image["SnapshotIds"]:
        ec2.delete_snapshot(SnapshotId=snap_id)
    print(f"AMI with id {image['ImageID']} was successfully deregistered")


######################
## MAIN
######################
def main(ami_id):
    res = ec2.describe_images(
        ImageIds=[ami_id]
    )['Images'][0]

    image = { 
        "ImageID": res['ImageId'], 
        "SnapshotIds": [ device['Ebs']['SnapshotId'] for device in res['BlockDeviceMappings'] if 'Ebs' in device.keys()]
    }
    
    print(image)

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
    if image["ImageID"] not in used_amis: deregister_image(image)
    return 0


if __name__ == "__main__":
    cmd_line_args = args_parser()
    main(cmd_line_args['ami_id'])
