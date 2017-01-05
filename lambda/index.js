"use strict"

exports.handler = (event, context, callback) => {

     const response = {
            "statusCode": 200,
            "headers": {},
            "body": JSON.stringify('hello world again')    
    };

    context.succeed(response);


    // callback(null, 'Hello world');
};
