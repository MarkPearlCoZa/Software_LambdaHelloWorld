#!/usr/bin/ruby -w

require 'io/console'
require 'aws-sdk'

LAMBDA_NAME = "LambdaHelloWolrdExample"
AWS_REGION = 'ap-southeast-2'
AWS_IAM_ROLE = 'arn:aws:iam::304434685916:role/service-role/lambda_basic_execution';

class LambdaPublisher
    
    def initialize
       @@client = Aws::Lambda::Client.new(region: AWS_REGION)
       @@logger = Logger.new(STDOUT)
       zipSourceCode
    end

    def update()
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
        end

        def createFunction
            result = @@client.create_function({
                function_name: LAMBDA_NAME,
                runtime: "nodejs4.3",
                role: AWS_IAM_ROLE,
                handler: "index.handler",
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

publisher = LambdaPublisher.new
publisher.update
