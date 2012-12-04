require 'spec_helper'

describe Api::V1::HeadingsController, "GET #show" do
  render_views

  context 'non-declarable heading' do
    let(:heading) { create :heading, :non_grouping,
                                     :non_declarable,
                                     :with_description,
                                     :with_chapter }

    let(:pattern) {
      {
        goods_nomenclature_item_id: heading.code,
        description: String,
        commodities: Array,
        chapter: Hash
      }.ignore_extra_keys!
    }

    context 'when record is present' do
      it 'returns rendered record' do
        get :show, id: heading, format: :json
        response.body.should match_json_expression pattern
      end
    end

    context 'when record is present and commodity has hidden commodities' do
      let!(:commodity1) { create :commodity, :with_indent, :with_description, :with_chapter, :declarable, goods_nomenclature_item_id: "#{heading.short_code}010000"}
      let!(:commodity2) { create :commodity, :with_indent, :with_description, :with_chapter, :declarable, goods_nomenclature_item_id: "#{heading.short_code}020000"}

      let!(:hidden_goods_nomenclature) { create :hidden_goods_nomenclature, goods_nomenclature_item_id: commodity2.goods_nomenclature_item_id }

      it 'does not include hidden commodities in the response' do
        get :show, id: heading, format: :json

        body = JSON.parse(response.body)
        body["commodities"].map{|c| c["goods_nomenclature_item_id"] }.should     include commodity1.goods_nomenclature_item_id
        body["commodities"].map{|c| c["goods_nomenclature_item_id"] }.should_not include commodity2.goods_nomenclature_item_id
      end
    end

    context 'when record is not present' do
      it 'returns not found if record was not found' do
        expect { get :show, id: "5555", format: :json }.to raise_error Sequel::RecordNotFound
      end
    end
  end

  context 'declarable heading' do
    let!(:heading) { create :heading, :with_indent,
                                      :with_chapter,
                                      :with_description,
                                      :declarable }
    let(:pattern) {
      {
        goods_nomenclature_item_id: heading.goods_nomenclature_item_id,
        description: String,
        chapter: Hash,
        import_measures: Array,
        export_measures: Array
      }.ignore_extra_keys!
    }

    context 'when record is present' do
      it 'returns rendered record' do
        get :show, id: heading, format: :json

        response.body.should match_json_expression pattern
      end
    end

    context 'when record is not present' do
      it 'returns not found if record was not found' do
        expect { get :show, id: "1234", format: :json }.to raise_error Sequel::RecordNotFound
      end
    end
  end
end
