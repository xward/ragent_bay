# How to use Protogen in a project #

Protogen is the MDI protocol generator. One gives it one (or several) file(s) to describe a protocol, along with a configuration file, and it generates either Ruby code (for the server) or Java code (for the device).

One can then build device services and server agents upon the generated code.

The generated code takes care of all the protocol details such as dispatching events, serializing messages and handling errors. All the user has to do is implementing callbacks.

## Key concepts ##

### Messages ###

Protogen messages are data structures used in the communication between a device and a server. The user code will directly manipulate such messages. A message is basically a collection of fields, a field being a basic type (integer, float...) or another message.

### Sequences ###

Sequences describe how messages are exchanged: if the server or the device can initiate a communication, what are the possible answers to a given message, when the communication ends... In a sequence definition, the user specify the name of callbacks he wants to be called when a message is received.

A sequence is a succession of "shots", a shot being the server (resp. the device) sending a message to the device (resp. the server).

### Stateless server ###

The server is stateless: it does not renember what previous requests it answered. To use session information, you can use Protogen cookies.

Begin stateless, the server can not handle as many errors as the device. For instance, the server can not know if it is supposed to wait for a device answer, and he can not even know that a device message is an answer to one of his previous messages.

## Defining a protocol ##

See the file `Protocol_file_description.md`. See the README for the configuration file to use and how to invoke Protogen from the command line to generate code.

## Protocol FAQ ##

### Can the device send several messages at once ? ###

Yes: in the protocol, define a message with an array field, and populate this field with the messages you want to send.

### Can the server send several messages at once ? ###

Yes: use an array field (see the question for the device) or, if you want to send the messages separately (so the device does not have to wait for all the messages to start processing the data), use a "multiple" shot (see the protocol file documentation)

## Ruby (server) ##

Protogen will generate a set of Ruby files. To use it, require the `protogen_apis.rb` generated file in your code wherever you want to use Protogen code. This file will require the other necessary Ruby files.

``` ruby
require_relative 'path/to/protogen_apis'
```

In Ruby code, Protogen messages are regular Ruby objects that have the same attributes as defined in the protocol file, and whose class name is the message name. They are defined in the namespace `Protogen_<agent_name>::Protogen::V<protocol_version>::Messages` (where the agent name is defined in the configuration file). For instance, if the protocol file includes:

``` javascript
{
  "protocol_version": 2,
  "messages": {
    "MyMessage": {
      "my_field": {"type": "string", "modifier":"required"}
      /* ... */
    }
  }
  /* ... */
}
```

then an example of Ruby code would be

``` ruby
msg = Protogen_my_agent::Protogen::V2::Messages::MyMessage.new(my_field: "initialization by hash is possible")
msg.my_field = "hello!"
```

A Protogen callback is a module method defined in a module whose name is the name of the sequence. Each sequence module belongs in a version module, and each version module belongs in top-level module.

This will become clear with an example. Let's take the following protocol file stub:

``` javascript
{
  "name": "MyProtocol",
  "protocol_version": 2,
  "package":"com.example.test",
  /* ... */
  "sequences": {
    "MySequence": {
      "first_shot":"FirstShot"
      "shots": [
        "FirstShot": {
          "way":"toServer",
          "received_callback":"my_callback",
          "message_type":"MyMessage",
          "next_shots":["NextShot"]
        },
        "NextShot": {
          "way":"toDevice",
          "received_callback":"deviceCallback",
          "message_type":"MyMessage"
        }
      ]
    }
  }
}
```

Then the corresponding code would be:

``` ruby
module Com_example_test_MyProtocol # the name depends on the protocol name and package

  module V2

    module MySequence

      def self.my_callback(msg) # note the 'self'
        protogen_object = msg.content # msg is a MessageClass, Protogen object is stored in msg.content
        # do stuff
        another_protogen_object_of_type_MyMessage
      end

    end

  end

end
```

A callback must return one of the message type defined in one of the next shots, unless the shot has no next shot in which case the return value does not matter. If the chosen next shot has "multiple: true" set, then the callback must return a non-empty array of messages (even if this array only has one element). Failure to do so will raise an error and abort the sequence.

To start a sequence from the server, use something like:

``` ruby
message = Protogen::V2::Messages::QuestionToDevice.new
message.query = "Did I say something?"
Protogen::Sequences.start(:AskToDevice, message, 359551033739060, "unstable", 2) # params: sequence name, message (or array of messages for a multiple shot), asset, account, version
```

If an exception is raised during a server callback, or if the returned value is not a valid Protogen message, the device will be notified that an error occured and thus will not wait for the timeout ("on_server_error" callback).

Messages also have a `cookies` field (array) in which you can set and read cookies.

```ruby
message = Protogen::V2::Messages::QuestionToDevice.new(query: "Hello!")
cookie = Protogen::V2::Cookies::Cart.new(last_item: "Book")
message.cookies = [cookie] # it is an array !

# later on...

def self.callback(msg)
  proto_object = msg.content
  unless proto_object.cookies.nil?
    # Yep, cookies!
  end
  # do more stuff
end
```

The server can send big messages to the device (the actual limit is a Protogen configuration parameter) ; Protogen will split big messages from the server before sending them, and reassemble them on the device. Note that the device can *not* split messages in the same way (see below for an explanation).

## Java (device) ##

To use Protogen, add the `.jar` generated by Protogen to your classpath. The device can only handle one protocol version.

Every class generated by Protogen lies in a package whose name is the protocol package.

To define callbacks, the user must implement the `ISequenceController` interface and every `I<sequence_name>Controller` interface.

A `I<sequence_name>Controller` defines the callbacks related to the current sequence. While the user has the control of whether he creates a new sequence controller or reuse an existing one when starting a sequence from the device, it is advised not to use the same controller for two sequences running concurrently, to limit multithreading issues.

The `ISequenceController` (global controller) is used by Protogen to retrieve instances of sequence controllers when the sequence is started by the server, and also defines the optionnal callbacks "generic_error_callback" and "out_of_sequence_callback".

Example:

* `CallbacksController.java`

``` java
// import statements
import com.example.test.ISequenceController;
// and so on ...

public class CallbacksController implements ISequenceController {

  // Called each time a new sequence is initiated by the server.
  // The returned object is used for the entire duration of the sequence (and thus does not need to be stateless).
  public IMySequenceController getMySequenceStartedByServerController() {
    return new MySequenceImpl();
  }

  // if the protocol file includes '"generic_error_callback":"onError"'
  public void onError() {
    // do stuff
  }

  // if the protocol file includes "out_of_sequence_callback":"outOfSequence"
  public void outOfSequence(MDIMessages.AbstractMessage msg, Sequence seq, Shot shot) {
    switch(seq) {
      case MYSEQUENCE:
        if(shot == Shot.MYSEQUENCE_MYSHOT) {
          if(msg instanceof MDIMessages.MyMessageForMyShot) {
            // handle the message even if is not part of a known sequence
            handle((MDIMessages.MyMessageForMyShot) msg);
          } else {
            assert false: "If this path is used then you have found a bug in Protogen";
          }
        } else {
          debug.error("Received a message out of a running sequence, can not do anything with it.");
        }
        break;
      default:
        debug.error("Received a message out of a running sequence, can not do anything with it.");
        break;
    }
  }

}
```

* `MySequenceImpl.java`

``` java
// import statements

public class MySequenceImpl implements IMySequenceController {

  // if defined in the protocol file: "aborted_callback":"onAbort"
  public void onAbort() {
    // TODO
  }

  public MDIMessages.AbstractMessage deviceCallback(MyMessage msg) {
    // TODO
  }

}
```

A controller must define every callback defined in the protocol file.

The callback return type is either `void` (last shot in a sequence, no answer expected) or the message type sent in the next shot (in this case, the object returned by the callback will be sent in the next shot). Such message types are a subclass of `MDIMessages.AbstractMessage`.

If the callback returns `null`, the sequence will be aborted (and the "aborted" callback called if defined). Use this to indicate to Protogen that an error occured.
If the callback returns a subclass of `MDIMessages.AbstractMessage` that is not compatible with any of the defined "next shots" then Protogen will error and call the "aborted" callback.

To start communicating with a server, the `Initial` class of the device component must initialize a `Dispatcher` object as follow:

``` java
Debug dbg = Component.getInstance().getDebug();
dbg.init(0);
Dispatcher dispatcher = new Dispatcher("com.mdi.services.sequences_test",
    Component.getInstance().getMessageGate(),
    Component.getInstance().getBinaryGate(),
    new CallbacksController(dbg),
    dbg);
```

To start a sequence:

``` java
MDIMessages.PoiRequest msg = new MDIMessages.PoiRequest();
msg.info = "some content";
dispatcher.startAskForPoisSequence(msg, new AskForPoisController()); // where PoiSequenceController implements the IAskForPoisController interface
```

The device message size must not exceed a limit (defined in Protogen configuration), otherwise an exception will be raised.
The device can not split messages the way the server does. Indeed, several message parts are not necessarily received by the same server. Assembling back the message would assume that the several servers running the agent share the same database for storing message parts. This assumption is currently valid (there is only one Redis server in production) but it was decided not to rely on it.

##### A note on callbacks #####

There are several situations in which the server will not answer the device message. When such a situation occurs, the corresponding callback (defined in the shot) will be called.
Once this callback is executed, Protogen checks for the existence of a retry policy in the shot. If the policy dictates that there is no attempt left, or if there is no retry policy, then Protogen will abort the sequence and call the "aborted" callback (defined at the sequence level).
Thus, the error callbacks such as "send_timeout_callback" will be called even if, because of the retry policy, the sequence did not abort.