# HoSAuth

Authentication module for HoS on air packages.

`npm install hos-auth`

requirement:
- rabbitMQ

## Example


``` coffee-script
HoSAuth = require('hos-auth')

authenticationService = new HoSAuth()
HoSService.connect()
```

In order to give the library access to the target rabbitMQ you can set following environmental variables:

- AMQP_URL
- AMQP_USERNAME
- AMQP_PASSWORD

All messages going sent in HoS environmental needs to be verified by this service, you need to listen to `message` event and according to content reject or accept a message in order to deliver into the destination or get back to the sender:

``` coffee-script
@HoSAuth.on 'message', (msg)=>
    if msg.content.foo is 'bar'
        msg.accept()
    else
        msg.reject()
```

While rejecting a message it is possible to specify the reason `msg.reject(reason, code)` default values are `reason = "fail to authenticat", code = 401`

## Running Tests

Run test by:

`gulp test`

requires local rabbitMQ or setting up `AMQP_URL` , `AMQP_USERNAME` and `AMQP_PASSWORD`

This software is licensed under the MIT License.
