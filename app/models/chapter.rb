require_relative 'goods_nomenclature'

class Chapter < GoodsNomenclature
  set_dataset filter("goods_nomenclatures.goods_nomenclature_item_id LIKE ?", '__00000000').
              order(:goods_nomenclature_item_id.asc)

  set_primary_key :goods_nomenclature_sid

  many_to_many :sections, left_key: :goods_nomenclature_sid,
                          join_table: :chapters_sections

  one_to_many :headings, dataset: -> {
    Heading.actual
           .filter("goods_nomenclature_item_id LIKE ? AND goods_nomenclature_item_id NOT LIKE '__00______'", chapter_id)
  }

  def short_code
    goods_nomenclature_item_id.first(2)
  end

  def section
    sections.first
  end
end
