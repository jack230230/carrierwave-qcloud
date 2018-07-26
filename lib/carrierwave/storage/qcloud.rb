require 'carrierwave'
require 'qcloud_cos' # use qcloud cos SDK

module CarrierWave
  module Storage
    ##
    #  qcloud storage engine
    #
    #  CarrierWave.configure do |config|
    #    config.storage           = :qcloud
    #    config.qcloud_app_id     = 'xxxxxx'
    #    config.qcloud_secret_id  = 'xxxxxx'
    #    config.qcloud_secret_key = 'xxxxxx'
    #    config.qcloud_bucket     = "bucketname"
    #  end
    #
    # wiki: https://github.com/richardkmichael/carrierwave-activerecord/wiki/Howto:-Adding-a-new-storage-engine
    # rdoc: http://www.rubydoc.info/gems/carrierwave/CarrierWave/Storage/Abstract
    class Qcloud < Abstract

      # config qcloud sdk by getting configuration from uplander
      def self.configure_qcloud_sdk(uploader)
        QcloudCos.configure do |config|
          config.app_id     = uploader.qcloud_app_id
          config.secret_id  = uploader.qcloud_secret_id
          config.secret_key = uploader.qcloud_secret_key
          config.bucket     = uploader.qcloud_bucket
          config.region     = uploader.qcloud_region
        end
      end

      # hook: store the file on qcloud
      def store!(file)
        self.class.configure_qcloud_sdk(uploader)

        qcloud_file = File.new(file)
        qcloud_file.path = uploader.store_path(identifier)
        qcloud_file.store
        qcloud_file
      end

      # hook: retrieve the file on qcloud
      def retrieve!(identifier)
        self.class.configure_qcloud_sdk(uploader)

        if uploader.file # file is present after store!
          uploader.file
        else
          file_path = uploader.store_path(identifier)
          File.new(nil).tap do |file|
            file.path = file_path
          end
        end
      end

      # store and retrieve file using qcloud-cos-sdk
      class File < CarrierWave::SanitizedFile
        attr_accessor :qcloud_info
        attr_accessor :path
        attr_accessor :url

        # store/upload file to qcloud
        def store
          result = QcloudCos.upload(path, file.to_file)

          if result != nil
            self.url = result
          end
        end

      end

    end
  end
end
