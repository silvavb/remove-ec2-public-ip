instanceId=$1

subnet=$(aws ec2 describe-instances \
		--filters Name=instance-id,Values=$instanceId \
		--query "Reservations[*].Instances[*].{Subnet:SubnetId}" \
		--output text)

echo "Creating a new temp ENI..."

eni=$(aws ec2 create-network-interface \
		--subnet-id subnet-c9d367e8 \
		--description "my temp network interface" \
		--query "NetworkInterface.NetworkInterfaceId" \
		--output text)

echo "done"

echo "Allocating a new temp EIP..."

eip=$(aws ec2 allocate-address \
		--query "AllocationId" \
		--output text)

echo "done"

echo "Associating EIP to EC2 Instance..."

assId=$(aws ec2 associate-address \
		--instance-id $instanceId \
		--allocation-id $eip	\
		--query "AssociationId" \
		--output text)

echo "done"


echo "Attaching temp ENI to EC2 Instance..."

attachmentId=$(aws ec2 attach-network-interface \
		--network-interface-id $eni \
		--instance-id $instanceId \
		--device-index 1 \
		--query "AttachmentId" \
		--output text)

echo "done"

echo "Disassociating EIP..."

aws ec2 disassociate-address --association-id $assId

echo "done"

echo "Releasing temp EIP..."

aws ec2 release-address --allocation-id $eip

echo "done"

echo "Detaching temp ENI..."

aws ec2 detach-network-interface --attachment-id $attachmentId

echo "done"

echo "Deleting temp ENI..."

sleep 100

aws ec2 delete-network-interface --network-interface-id $eni

echo "done"

