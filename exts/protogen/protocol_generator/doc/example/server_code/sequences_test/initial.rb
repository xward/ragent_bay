module Initial_agent_sequences_test

  def new_presence_from_device(presence)
    # Write your code here
  end

  def new_msg_from_device(msg)
    # Write your code here
  end

  def new_track_from_device(track)
    # Write your code here
  end

  def new_order(order)
    message = Protogen::Messages::QuestionToDevice.new
    message.query = "Did I say something?"
    Protogen::Sequences.startAskToDeviceSequence(message, 359551033739060, "unstable")
  end

  #################################################
  # Implement below callbacks defined in Protogen #

end