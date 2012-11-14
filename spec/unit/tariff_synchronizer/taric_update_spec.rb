require 'spec_helper'
require 'tariff_synchronizer'
require 'mocha/standalone'

describe TariffSynchronizer::TaricUpdate do
  it_behaves_like 'Base Update'

  let(:example_date)      { Forgery(:date).date }

  before do
    TariffSynchronizer.admin_email = "user@example.com"
  end

  describe '.download' do
    let(:taric_update_name)  { "TGB#{example_date.strftime("%y")}#{example_date.yday}.xml" }
    let(:taric_query_url)    { "#{TariffSynchronizer.host}/taric/TARIC3#{example_date.strftime("%Y%m%d")}" }
    let(:blank_response)     { build :response, content: nil }
    let(:not_found_response) { build :response, :not_found }
    let(:success_response)   { build :response, :success, content: 'abc' }
    let(:failed_response)    { build :response, :failed }
    let(:update_url)         { "#{TariffSynchronizer.host}/taric/#{taric_update_name}" }


    before do
      TariffSynchronizer.host = "http://example.com"
      prepare_synchronizer_folders
    end

    context "when file for the day is found" do
      let(:query_response)     { build :response, :success, url: taric_query_url,
                                                         content: taric_update_name }
      before {
        TariffSynchronizer::TaricUpdate.expects(:download_content)
                                       .with(taric_query_url)
                                       .returns(query_response)
      }

      it 'downloads Taric file for specific date' do
        TariffSynchronizer::TaricUpdate.expects(:download_content)
                                       .with(update_url)
                                       .returns(blank_response)

        TariffSynchronizer::TaricUpdate.download(example_date)
      end

      it 'writes Taric file contents to file if they are not blank' do
        TariffSynchronizer::TaricUpdate.expects(:download_content)
                                       .with(update_url)
                                       .returns(success_response)

        TariffSynchronizer::TaricUpdate.download(example_date)

        File.exists?("#{TariffSynchronizer.root_path}/taric/#{example_date}_#{taric_update_name}").should be_true
        File.read("#{TariffSynchronizer.root_path}/taric/#{example_date}_#{taric_update_name}").should == 'abc'
      end

      it 'does not write Taric file contents to file if they are blank' do
        TariffSynchronizer::TaricUpdate.expects(:download_content)
                                       .with(update_url)
                                       .returns(blank_response)

        TariffSynchronizer::TaricUpdate.download(example_date)
        File.exists?("#{TariffSynchronizer.root_path}/taric/#{example_date}_#{taric_update_name}").should be_false
      end
    end

    context 'when file for the day is not found' do
      before {
        TariffSynchronizer::TaricUpdate.expects(:download_content)
                                       .with(taric_query_url)
                                       .returns(not_found_response)

        TariffSynchronizer::TaricUpdate.download(example_date)
      }

      it 'does not write Taric file contents to file if they are blank' do
        File.exists?("#{TariffSynchronizer.root_path}/taric/#{example_date}_#{taric_update_name}").should be_false
      end

      it 'creates not found entry' do
        TariffSynchronizer::TaricUpdate.missing
                                       .with_issue_date(example_date)
                                       .present?.should be_true
      end
    end

    context 'retry count exceeded (failed update)' do
      let(:update_url) { "#{TariffSynchronizer.host}/taric/abc" }

      before {
        TariffSynchronizer.retry_count = 1

        TariffSynchronizer::TaricUpdate.expects(:send_request)
                                       .with(taric_query_url)
                                       .returns(success_response)

        TariffSynchronizer::TaricUpdate.expects(:send_request)
                                       .with(update_url)
                                       .twice
                                       .returns(failed_response)

        TariffSynchronizer::TaricUpdate.download(example_date)
      }

      it 'does not write file to file system' do
        File.exists?("#{TariffSynchronizer.root_path}/taric/#{example_date}_#{taric_update_name}").should be_false
      end

      it 'creates failed update entry' do
        TariffSynchronizer::TaricUpdate.failed
                                       .with_issue_date(example_date)
                                       .present?.should be_true
      end
    end

    context 'downloaded file is blank' do
      let(:update_url) { "#{TariffSynchronizer.host}/taric/abc" }
      let(:blank_success_response)   { build :response, :success, content: '' }

      before {
        TariffSynchronizer::TaricUpdate.expects(:send_request)
                                       .with(taric_query_url)
                                       .returns(success_response)

        TariffSynchronizer::TaricUpdate.expects(:send_request)
                                       .with(update_url)
                                       .returns(blank_success_response)

        TariffSynchronizer::TaricUpdate.download(example_date)
      }

      it 'does not write file to file system' do
        File.exists?("#{TariffSynchronizer.root_path}/taric/#{example_date}_#{taric_update_name}").should be_false
      end

      it 'creates failed update entry' do
        TariffSynchronizer::TaricUpdate.failed
                                       .with_issue_date(example_date)
                                       .present?.should be_true
      end
    end

    after  { purge_synchronizer_folders }
  end

  describe "#apply" do
    let(:state) { :pending }
    let!(:example_taric_update) { create :taric_update, example_date: example_date }

    before {
      prepare_synchronizer_folders
      create_taric_file :pending, example_date
    }

    it 'executes Taric importer' do
      mock_importer = stub_everything
      TariffImporter.expects(:new).with(example_taric_update.file_path, TaricImporter).returns(mock_importer)

      TariffSynchronizer::TaricUpdate.first.apply
    end

    it 'updates file entry state to processed' do
      mock_importer = stub_everything
      TariffImporter.expects(:new).with(example_taric_update.file_path, TaricImporter).returns(mock_importer)

      TariffSynchronizer::TaricUpdate.pending.count.should == 1
      TariffSynchronizer::TaricUpdate.first.apply
      TariffSynchronizer::TaricUpdate.pending.count.should == 0
      TariffSynchronizer::TaricUpdate.applied.count.should == 1
    end

    it 'does not move file to processed if import fails' do
      mock_importer = stub
      mock_importer.expects(:import).raises(TaricImporter::ImportException)
      TariffImporter.expects(:new).with(example_taric_update.file_path, TaricImporter).returns(mock_importer)

      TariffSynchronizer::TaricUpdate.pending.count.should == 1
      rescuing { TariffSynchronizer::TaricUpdate.first.apply }
      TariffSynchronizer::TaricUpdate.pending.count.should == 1
      TariffSynchronizer::TaricUpdate.applied.count.should == 0
    end

    after  { purge_synchronizer_folders }
  end

  describe '.rebuild' do
    before {
      prepare_synchronizer_folders
      create_taric_file :pending, example_date
    }

    context 'entry for the day/update does not exist yet' do
      it 'creates db record from available file name' do
        TariffSynchronizer::BaseUpdate.count.should == 0

        TariffSynchronizer::TaricUpdate.rebuild

        TariffSynchronizer::BaseUpdate.count.should == 1
        first_update = TariffSynchronizer::BaseUpdate.first
        first_update.issue_date.should == example_date
      end
    end

    context 'entry for the day/update exists already' do
      let!(:example_taric_update) { create :taric_update, example_date: example_date }

      it 'does not create db record if it is already available for the day/update type combo' do
        TariffSynchronizer::BaseUpdate.count.should == 1

        TariffSynchronizer::TaricUpdate.rebuild

        TariffSynchronizer::BaseUpdate.count.should == 1
      end
    end

    after  { purge_synchronizer_folders }
  end
end
