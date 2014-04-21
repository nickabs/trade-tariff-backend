require 'tariff_synchronizer/base_update'
require 'tariff_synchronizer/file_service'
require 'ostruct'

module TariffSynchronizer
  class TaricUpdate < BaseUpdate
    class << self
      def download(date)
        taric_updates_for(date).tap do |taric_updates|
          if taric_updates.any?
            taric_updates.each do |taric_update|
              instrument("download_taric.tariff_synchronizer",
                         date: date,
                         url: taric_update.url) do
                file_name_for(date, taric_update.file_name).tap do |local_file_name|
                  unless update_file_exists?(local_file_name)
                    download_content(taric_update.url).tap { |response|
                      create_entry(date, response, local_file_name)
                    }
                  end
                end
              end
            end
          # We will be retrying a few more times today, so do not create
          # missing record until we are sure
          elsif date < Date.today
            create_update_entry(date, BaseUpdate::MISSING_STATE, missing_update_name_for(date))
            instrument("not_found.tariff_synchronizer",
                       date: date,
                       url: taric_query_url_for(date))
            false
          end
        end
      end

      def file_name_for(date, update_name)
        "#{date}_#{update_name}"
      end

      def update_type
        :taric
      end

      def rebuild
        Dir[File.join(Rails.root, TariffSynchronizer.root_path, 'taric', '*.xml')].each do |file_path|
          date, file_name = parse_file_path(file_path)

          create_update_entry(Date.parse(date), BaseUpdate::PENDING_STATE, Pathname.new(file_path).basename.to_s)
        end
      end
    end

    def apply
      super
      if file_exists?
        instrument("apply_taric.tariff_synchronizer", filename: filename) do
          TaricImporter.new(file_path, issue_date).import

          mark_as_applied
        end
      end
    rescue TaricImporter::ImportException, TariffImporter::NotFound => e
      instrument(
        "failed_update.tariff_synchronizer",
        exception: e,
        update: self,
        database_queries: @database_queries
      )

      mark_as_failed

      raise Sequel::Rollback
    end

    private

    def self.taric_update_name_for(date)
      taric_query_url = taric_query_url_for(date)

      instrument("get_taric_update_name.tariff_synchronizer",
                 date: date,
                 url: taric_query_url) do
        response = download_content(taric_query_url)
        response.content.split("\n").map{|name| name.gsub(/[^0-9a-zA-Z\.]/i, '') } if response.success? && response.content_present?
      end
    end

    def self.taric_updates_for(date)
      (taric_update_name_for(date) || []).map { |name|
        OpenStruct.new(
          file_name: name,
          url: TariffSynchronizer.taric_update_url_template % { host: TariffSynchronizer.host,
                                                                file_name: name }
        )
      }
    end

    def self.taric_query_url_for(date)
      date_query = Date.parse(date.to_s).strftime("%Y%m%d")
      TariffSynchronizer.taric_query_url_template % { host: TariffSynchronizer.host,
                                                      date: date_query}
    end
  end
end
