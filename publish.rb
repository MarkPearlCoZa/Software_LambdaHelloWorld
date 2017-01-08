#!/usr/bin/ruby -w

require 'io/console'
require 'aws-sdk'

AWS_ROLE_NAME = 'LambdaFunctions'
AWS_ACCOUNT_NUM = '304434685916'
AWS_REGION = 'ap-southeast-2'
AWS_IAM_ROLE = 'arn:aws:iam::' + AWS_ACCOUNT_NUM + ':role/service-role/' + AWS_ROLE_NAME;

class IAMCreator

    def initialize
       @@client = Aws::IAM::Client.new(region: AWS_REGION)
    end    

    def loadPolicyDocument()
        file = File.open("iam-policy-arn.txt", "rb")
        contents = file.read
        file.close()
        return contents;
    end

    def ensureRoleExists
       if (!arnExists)
         createRole
       end
    end

    def createRole
        resp = @@client.create_role({
          assume_role_policy_document: loadPolicyDocument, 
          path:'/service-role/',
          role_name: AWS_ROLE_NAME, 
        })
    end

    def getRoleArns
        @@client.list_roles().roles.map {|role| role.role_name}
    end

    def arnExists
        getRoleArns.include?(AWS_ROLE_NAME);
    end
end

class LambdaPublisher

    LAMBDA_NAME = "LambdaHelloWolrdExample"
    AWS_RUNTIME = 'nodejs4.3'
    AWS_HANDLER = 'index.handler'
    
    def initialize
       @@client = Aws::Lambda::Client.new(region: AWS_REGION)
       @@logger = Logger.new(STDOUT)
       zipSourceCode
    end

    def ensureLatestCode()
        if functionExists(LAMBDA_NAME)
           updateFunction
            @@logger.info("function updated")
        else
            createFunction
            @@logger.info("function created")
        end
    end

    private 

        def zipSourceCode()
            FileUtils.rm_rf('index.zip')
            Dir.chdir('lambda')
            `zip -X -r ../index.zip *`
            Dir.chdir('..')
        end

        def loadZippedSourceCode()
            file = File.open("index.zip", "rb")
            contents = file.read
            file.close()
            return contents;
        end

        def updateFunction
            result = @@client.update_function_code({
                function_name: LAMBDA_NAME,
                zip_file: loadZippedSourceCode
            })

            result = @@client.update_function_configuration({
                function_name: LAMBDA_NAME,
                handler: AWS_HANDLER,
                role: AWS_IAM_ROLE,
                runtime: AWS_RUNTIME
            })
        end

        def createFunction
            result = @@client.create_function({
                function_name: LAMBDA_NAME,
                runtime: AWS_RUNTIME,
                role: AWS_IAM_ROLE,
                handler: AWS_HANDLER,
                code: {
                    zip_file: loadZippedSourceCode
                },
                publish: true
            })
        end

        def getFunctionNames
            functions = @@client.list_functions
            functions.functions.map { |x| x.function_name }
        end

        def functionExists(functionName)
            getFunctionNames.include?(functionName);
        end
end

puts AWS_IAM_ROLE
iam = IAMCreator.new
puts iam.ensureRoleExists
publisher = LambdaPublisher.new
publisher.ensureLatestCode

