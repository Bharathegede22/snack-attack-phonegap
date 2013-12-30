#ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
#  :access_key_id     => 'AKIAJADJVBBLFOE3LPFA',
#  :secret_access_key => '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'
AWS.config(access_key_id: AWS_SES_ID, secret_access_key: AWS_SES_KEY)
