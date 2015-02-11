module RailsMailgun
  class Mail
    def initialize(settings)
      @settings = settings
    end
    attr_accessor :settings

    def deliver!(mail)
      client = Mailgun::Client.new(settings[:api_key])
      client.send_message(settings[:api_host], message_object(mail))
    end

    private

    def message_object(mail)
      message_object = Mailgun::MessageBuilder.new
      message_object.set_from_address( "Conviso CSC <noreply@conviso.com.br>" )
      mail.to.each  { |t| message_object.add_recipient(:to,  t) }
      add_cc_emails_to_message_object(message_object, mail)
      add_bcc_emails_to_message_object(message_object, mail)

      message_object.set_subject(mail.subject)

      if mail.multipart?
        set_message_object_body(message_object, mail.parts.first)

        mail.attachments.each do |attachment|
          tempfile = create_tempfile_from_attachment(attachment)
          message_object.add_attachment(tempfile.path, attachment.filename)
        end
      else
        set_message_object_body(message_object, mail)
      end

      message_object
    end

    def set_message_object_body(message_object, mail)
      if mail.content_type.match(/html/)
        message_object.set_html_body(mail.body.to_s)
      else
        message_object.set_text_body(mail.body.to_s)
      end
    end

    def add_bcc_emails_to_message_object(message_object, mail)
      return unless mail.bcc.present?

      bcc_emails = [mail.bcc].flatten
      bcc_emails.each { |t| message_object.add_recipient(:bcc, t) }
    end

    def add_cc_emails_to_message_object(message_object, mail)
      return unless mail.cc.present?

      cc_emails = [mail.cc].flatten
      cc_emails.each { |t| message_object.add_recipient(:cc, t) }
    end

    def create_tempfile_from_attachment(attachment)
      tempfile = Tempfile.new(attachment.filename)
      tempfile.binmode
      tempfile.write(attachment.body.raw_source)
      tempfile.close
      tempfile
    end
  end
end
