## This file was auto-generated by CloudCoreo CLI
## This file was automatically generated using the CloudCoreo CLI
##
## This config.rb file exists to create and maintain services not related to compute.
## for example, a VPC might be maintained using:
##
## coreo_aws_vpc_vpc "my-vpc" do
##   action :sustain
##   cidr "12.0.0.0/16"
##   internet_gateway true
## end
##
coreo_aws_vpc_vpc "${VPC_NAME}" do
  action :find
  cidr "${VPC_CIDR}"
  tags(${VPC_TAGS}) unless ${VPC_TAGS}.nil? || ${VPC_TAGS}.empty?
end

coreo_aws_vpc_routetable "${PRIVATE_ROUTE_NAME}" do
  action :find
  vpc "${VPC_NAME}"
  tags(${PRIVATE_ROUTE_SEARCH_TAGS}) unless (${PRIVATE_ROUTE_SEARCH_TAGS}.nil? || ${PRIVATE_ROUTE_SEARCH_TAGS}.empty?)
end

coreo_aws_vpc_subnet "${PRIVATE_SUBNET_NAME}" do
  action :find
  route_table "${PRIVATE_ROUTE_NAME}"
  vpc "${VPC_NAME}"
end

coreo_aws_ec2_securityGroups "${SERVER_NAME}${SUFFIX}" do
  action :sustain
  description "Server security group"
  vpc "${VPC_NAME}"
  allows [ 
          { 
            :direction => :ingress,
            :protocol => :tcp,
            :ports => ${SERVER_INGRESS_PORTS},
            :cidrs => ${SERVER_INGRESS_CIDRS}
          },{ 
            :direction => :egress,
            :protocol => :tcp,
            :ports => ${SERVER_EGRESS_PORTS},
            :cidrs => ${SERVER_EGRESS_CIDRS}
          }
    ]
end

coreo_aws_iam_policy "${SERVER_NAME}${SUFFIX}" do
  action :sustain
  policy_name "${SERVER_NAME}${SUFFIX}Role"
  policy_document <<-EOH
{
  "Statement": [
    {
      "Effect": "Deny",
      "Resource": [
          "*"
      ],
      "Action": [ 
          "*"
      ]
    }
  ]
}
EOH
end

coreo_aws_iam_instance_profile "${SERVER_NAME}${SUFFIX}" do
  action :sustain
  policies ["${SERVER_NAME}${SUFFIX}"]
end

coreo_aws_ec2_instance "${SERVER_NAME}${SUFFIX}" do
  action :define
  image_id "${AWS_LINUX_AMI}"
  size "${SERVER_SIZE}"
  security_groups ["${SERVER_NAME}${SUFFIX}"]
  role "${SERVER_NAME}${SUFFIX}"
  ssh_key("${SERVER_KEYPAIR}") unless "${SERVER_KEYPAIR}".nil? || "${SERVER_KEYPAIR}".length == 0
  upgrade_trigger "${SERVER_UPGRADE_TRIGGER}"
  disks [
         {
           :device_name => "/dev/xvda",
           :volume_size => ${ROOT_VOLUME_SIZE_IN_GB}
         }
        ]
  environment_variables(${ENVIRONMENT_VARIABLES}) unless ${ENVIRONMENT_VARIABLES}.nil? || ${ENVIRONMENT_VARIABLES}.empty?
end

coreo_aws_ec2_autoscaling "${SERVER_NAME}${SUFFIX}" do
  action :sustain 
  minimum((${AUTOMATIC_ON_OFF} ? ((${AUTOMATIC_ON_HOUR}..(${AUTOMATIC_OFF_HOUR}-1)).include?(Time.new.getlocal("${TIMEZONE_OFFSET}").hour) ? ${AUTOSCALING_GROUP_MINIMUM} : 0) : ${AUTOSCALING_GROUP_MINIMUM}))
  maximum((${AUTOMATIC_ON_OFF} ? ((${AUTOMATIC_ON_HOUR}..(${AUTOMATIC_OFF_HOUR}-1)).include?(Time.new.getlocal("${TIMEZONE_OFFSET}").hour) ? ${AUTOSCALING_GROUP_MAXIMUM} : 0) : ${AUTOSCALING_GROUP_MAXIMUM}))
  server_definition "${SERVER_NAME}${SUFFIX}"
  subnet "${PRIVATE_SUBNET_NAME}"
end
