#!/usr/bin/ruby -w

require 'io/console'
require 'aws-sdk'

LAMBDA_NAME = "LambdaHelloWolrdExample"
AWS_REGION = 'ap-southeast-2'
AWS_IAM_ROLE = 'arn:aws:iam::304434685916:role/service-role/lambda_basic_execution';

def zipProject()
    FileUtils.rm_rf('index.zip')
    Dir.chdir('lambda')
    `zip -X -r ../index.zip *`
    Dir.chdir('..')
    file = File.open("index.zip", "rb")
    contents = file.read
    file.close()
    return contents;
end

def deleteLambdaFunction
    client = Aws::Lambda::Client.new(region: AWS_REGION)

    result  = client.delete_function({
        function_name: LAMBDA_NAME
    })
end

def updateLambdaFunction
    client = Aws::Lambda::Client.new(region: AWS_REGION)

    result  = client.update_function_code({
        function_name: LAMBDA_NAME,
        zip_file: zipProject()
    })
end

def createLambdaFunction

    client = Aws::Lambda::Client.new(region: AWS_REGION)

    result = client.create_function({
        function_name: LAMBDA_NAME,
        runtime: "nodejs4.3",
        role: AWS_IAM_ROLE,
        handler: "index.handler",
        code: {
            zip_file: zipProject
        },
        publish: true
    })
end

def getLambdaFunctionNames
    client = Aws::Lambda::Client.new(region: AWS_REGION)
    functions = client.list_functions
    functions.functions.map { |x| x.function_name }
end

def lambdaFunctionExists(functionName)
    getLambdaFunctionNames.include?(functionName);
end

puts "starting..."

if lambdaFunctionExists(LAMBDA_NAME)
   puts 'updating...'
   updateLambdaFunction
else
    puts 'creating...'
    createLambdaFunction
end
puts "done..."
