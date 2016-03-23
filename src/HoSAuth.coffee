module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    HoSAuthConsumer     = require("./HoSAuthConsumer")(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise)
    HoSAuthPublisher    = require("./HoSAuthPublisher")(amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise)

    class HoSAuthCom extends EventEmitter
        _serviceId: null
        Publisher: null

        constructor: (@amqpurl, @username, @password, @HoSPush = 'HoSPush', @HoSPull = 'HoSPull') ->
            @HoSAuthConsumers = []
            @_messagesToReply = {}
            @_consumerNumber = 2
            @_prefetch = 1
            @_name = 'auth'

            super()

            ServiceInfo =
                ID: crypto.randomBytes(10).toString('hex')
                CreateOn: Date.now()
                HostName: os.hostname()

            @_serviceId = URLSafeBase64.encode(new Buffer(JSON.stringify ServiceInfo))

        connect: ()->
            promises = []
            for i in [0 .. @_consumerNumber - 1]
                con = new HoSAuthConsumer(@, @amqpurl, @username, @password)
                promises.push con.connect()
                con.on 'error', (msg)=>
                    console.log msg
                con.on 'message', (msg)=>
                    @_processMessage(msg)
                @HoSAuthConsumers.push con

            @Publisher = new HoSAuthPublisher(@, @amqpurl, @username, @password)
            promises.push @Publisher.connect()
            Promise.all(promises)

        destroy: ()->
            @Publisher._amqpConnection.close()

            for con in @HoSAuthConsumers
                con._amqpConnection.close()

        _processMessage: (msg)->
            @emit("message", msg)
