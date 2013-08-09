require_relative 'goods_nomenclature'

class Chapter < GoodsNomenclature
  include Tire::Model::Search

  plugin :json_serializer
  plugin :oplog, primary_key: :goods_nomenclature_sid
  plugin :conformance_validator

  set_dataset filter("goods_nomenclatures.goods_nomenclature_item_id LIKE ?", '__00000000').
              order(Sequel.asc(:goods_nomenclature_item_id))

  set_primary_key [:goods_nomenclature_sid]

  many_to_many :sections, left_key: :goods_nomenclature_sid,
                          join_table: :chapters_sections

  one_to_many :headings, dataset: -> {
    Heading.actual
           .filter("goods_nomenclature_item_id LIKE ? AND goods_nomenclature_item_id NOT LIKE '__00______'", relevant_headings)
           .where(Sequel.~(goods_nomenclatures__goods_nomenclature_item_id: HiddenGoodsNomenclature.codes))
  }

  one_to_one :chapter_note, dataset: -> {
    ChapterNote.where(chapter_id: to_param)
  }

  # Tire configuration
  tire do
    index_name    'chapters'
    document_type 'chapter'

    mapping do
      indexes :description,        analyzer: 'snowball'
    end
  end

  dataset_module do
    def by_code(code = "")
      filter("goods_nomenclatures.goods_nomenclature_item_id LIKE ?", "#{code.to_s.first(2)}00000000")
    end
  end

  def short_code
    goods_nomenclature_item_id.first(2)
  end

  # Override to avoid lookup, this is default behaviour for chapters.
  def number_indents
    0
  end

  def to_param
    short_code
  end

  def section
    sections.first
  end

  def serializable_hash
    {
      id: goods_nomenclature_sid,
      goods_nomenclature_item_id: goods_nomenclature_item_id,
      producline_suffix: producline_suffix,
      validity_start_date: validity_start_date,
      validity_end_date: validity_end_date,
      description: description.downcase,
      section: {
        numeral: section.numeral,
        title: section.title,
        position: section.position
      }
    }
  end

  def to_indexed_json
    serializable_hash.to_json
  end

  private

  def relevant_headings
    "#{short_code}__000000"
  end
end
