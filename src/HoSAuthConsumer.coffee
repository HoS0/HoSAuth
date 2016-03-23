module.exports = (amqp, os, crypto, EventEmitter, URLSafeBase64, uuid, Promise) ->
    class HoSConsumer extends EventEmitter
        _amqpConnection: null
        _serviceId: null

        constructor: (@_HoSAuth, @amqpurl = process.env.AMQP_URL, @username = process.env.AMQP_USERNAME, @password = process.env.AMQP_PASSWORD) ->
            @_options= {durable: true, autoDelete: true}
            @isClosed= false
            super()

        connect: ()->
            @_serviceId = @_HoSAuth._serviceId

            connectionOk = amqp.connect("amqp://#{@username}:#{@password}@#{@amqpurl}")

            connectionOk.catch (err)=>
                @isClosed = true
                @emit('error', err)
                reject()

            connectionOk.then (conn)=>
                @_amqpConnection = conn
                return conn.createChannel()

            .then (ch)=>
                ch.prefetch(@_HoSAuth._prefetch)
                ch.on "close", () =>
                    isClosed = true
                ch.on "error", () =>
                    isClosed = true

                @consumeChannel = ch
                @_CreatServiceExchange()

        _CreatServiceExchange: ()->
            if @consumeChannel
                HoSExOk = @consumeChannel.assertExchange(@_HoSAuth.HoSPush, 'topic', {durable: true})
                HoSExOk.then ()=>
                    @_CreateQueue "#{@_HoSAuth._name}", "#"
            else
                @emit('error', 'no consume channel')
                reject()

        _CreateQueue: (queueName, bindingKey)->
            @consumeChannel.assertQueue(queueName, @_options)
            .then ()=>
                @consumeChannel.bindQueue(queueName, @_HoSAuth.HoSPush, bindingKey).then ()=>
                    pm = (msg)=>
                        @_processMessage(msg)
                    @consumeChannel.consume(queueName, pm)

        _processMessage: (msg)->
            if msg.properties.contentType is 'application/json' and msg.content
                msg.content = JSON.parse msg.content

            msg.accept = ()=>
                @consumeChannel.ack(msg)
                @_HoSAuth.Publisher.sendReply(msg, msg.content, msg.fields.routingKey)

            msg.reject = (reason = "fail to authenticat", code = 401)=>
                @consumeChannel.ack(msg)
                msg.properties.headers.error = code
                msg.properties.headers.errorMessage = reason
                @_HoSAuth.Publisher.sendReply(msg, {error: reason, issuedBy: @_serviceId}, msg.properties.appId)

            @emit('message', msg)
