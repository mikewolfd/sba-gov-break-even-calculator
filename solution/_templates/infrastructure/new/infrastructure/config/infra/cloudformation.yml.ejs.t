---
    to: infrastructure/config/infra/cloudformation.yml
---
# This Template creates an S3 bucket and publishes it to the cloudfront CDN.
# Needed services and resources can be added here as needed

Conditions:
  IsDev: !Equals [ '${self:custom.settings.envType}', 'dev' ]
  IsProd: !Equals [ '${self:custom.settings.envType}', 'prod' ]

Resources:

  # =============================================================================================
  # S3 Buckets
  # =============================================================================================

  # S3 Bucket for the static website
  WebsiteBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: ${self:custom.settings.websiteBucketName}
      WebsiteConfiguration:
        IndexDocument: index.html
        ErrorDocument: index.html

  WebsiteBucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Ref WebsiteBucket
      PolicyDocument:
        Statement:
        - Action:
            - 's3:GetObject'
          Effect: Allow
          Principal:
            AWS: !Join ['',['arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ', !Ref 'CloudFrontOAI']]
          Resource:
            - !Join ['', ['arn:aws:s3:::', !Ref 'WebsiteBucket', '/*']]

  # =============================================================================================
  # WAF ACL for Cloudfront Distribution
  # =============================================================================================

  # Web Application Firewall Access Control List
  rWAFWebACL:
    Type: AWS::WAFv2::WebACL
    Properties:
      Name: !Sub WebApplicationFirewall-${AWS::StackName}
      Scope: CLOUDFRONT
      Description: This WebACL is used to filter requests destined for a CloudFront distribution associated with a static S3 website.
      DefaultAction:
        Allow: {}
      VisibilityConfig:
        SampledRequestsEnabled: true
        CloudWatchMetricsEnabled: true
        MetricName: !Sub WAF-${AWS::StackName}
      Rules:
        - Name: RestrictGeoMatch
          Priority: 0
          Action:
            Block: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: RestrictGeoMatchMetric
          Statement:
            NotStatement:
              Statement:
                GeoMatchStatement:
                    CountryCodes:
                      - US
        - Name: AWSManagedRulesCommonRuleSet
          Priority: 1
          OverrideAction:
            None: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: AWSManagedRules-CommonRulesSet
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesCommonRuleSet
              ExcludedRules: []
        - Name: AWSManagedRulesAmazonIPReputation
          Priority: 2
          OverrideAction:
            None: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: AWSManagedRules-AmazonIPReputation
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesAmazonIpReputationList
              ExcludedRules: []
        - Name: RateLimitRule
          Priority: 3
          Action:
            Block: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: RateLimitRule
          Statement:
            RateBasedStatement:
              AggregateKeyType: IP
              Limit: 2000

  # =============================================================================================
  # CloudFront
  # =============================================================================================

  WebsiteCloudFront:
    Type: AWS::CloudFront::Distribution
    DependsOn:
      - WebsiteBucket
    Properties:
      DistributionConfig:
        Comment: 'CloudFront Distribution pointing to ${self:custom.settings.websiteBucketName}'
        Origins:
          - DomainName: '${self:custom.settings.websiteBucketName}.s3.amazonaws.com'
            Id: S3Origin
            S3OriginConfig:
              OriginAccessIdentity:  !Join ['', ['origin-access-identity/cloudfront/', !Ref 'CloudFrontOAI']]
        Enabled: true
        HttpVersion: 'http2'
        DefaultRootObject: index.html
        CustomErrorResponses:
          - ErrorCachingMinTTL: 300
            ErrorCode: 404
            ResponseCode: 200
            ResponsePagePath: /index.html
          - ErrorCachingMinTTL: 300
            ErrorCode: 403
            ResponseCode: 200
            ResponsePagePath: /index.html
        DefaultCacheBehavior:
          DefaultTTL: ${self:custom.settings.cloudfrontDefaultTtl}
          MinTTL: ${self:custom.settings.cloudfrontMinTtl}
          MaxTTL: ${self:custom.settings.cloudfrontMaxTtl}
          AllowedMethods:
            - GET
            - HEAD
            - OPTIONS
          Compress: true
          TargetOriginId: S3Origin
          ForwardedValues:
            QueryString: true
            Cookies:
              Forward: none
          ViewerProtocolPolicy: redirect-to-https
        Aliases:
          - '${self:custom.settings.websiteDomain}'
        ViewerCertificate:
           AcmCertificateArn: !Sub arn:aws:acm:${AWS::Region}:${AWS::AccountId}:certificate/${self:custom.settings.websiteAcmArn}
           MinimumProtocolVersion: TLSv1.1_2016
           SslSupportMethod: sni-only
        PriceClass: PriceClass_100
        WebACLId: !GetAtt rWAFWebACL.Arn
        Restrictions:
          GeoRestriction:
            Locations:
              - 'US'
            RestrictionType: 'whitelist'

  CloudFrontOAI:
    Type: AWS::CloudFront::CloudFrontOriginAccessIdentity
    Properties:
      CloudFrontOriginAccessIdentityConfig:
        Comment: 'OAI for ${self:custom.settings.websiteBucketName}'

  # =============================================================================================
  # KMS Insertion Point (do not change this text, it is being used by hygen cli)
  # =============================================================================================


  # =============================================================================================
  # SQS Insertion Point (do not change this text, it is being used by hygen cli)
  # =============================================================================================


Outputs:

  WebsiteUrl:
    Description: URL for the main website hosted on S3 via CloudFront
    Value: !Join ['', ['https://', !GetAtt [WebsiteCloudFront, DomainName]]]

  WebsiteBucket:
    Description: The bucket name of the static website
    Value: !Ref WebsiteBucket

  CloudFrontEndpoint:
    Value: !GetAtt [WebsiteCloudFront, DomainName]
    Description: Endpoint for CloudFront distribution for the website

  CloudFrontId:
    Value: !Ref WebsiteCloudFront
    Description: Id of the CloudFront distribution


