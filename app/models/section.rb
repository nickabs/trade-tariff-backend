class Section < Sequel::Model
  include Tire::Model::Search

  plugin :json_serializer

  many_to_many :chapters, dataset: -> {
    Chapter.join_table(:inner, :chapters_sections, chapters_sections__goods_nomenclature_sid: :goods_nomenclatures__goods_nomenclature_sid)
           .join_table(:inner, :sections, chapters_sections__section_id: :sections__id)
           .with_actual(Chapter)
           .where(sections__id: id)
  }, eager_loader: (proc do |eo|
    eo[:rows].each{|section| section.associations[:chapters] = []}

    id_map = eo[:id_map]

    Chapter.join_table(:inner, :chapters_sections, chapters_sections__goods_nomenclature_sid: :goods_nomenclatures__goods_nomenclature_sid)
           .join_table(:inner, :sections, chapters_sections__section_id: :sections__id)
           .eager(:goods_nomenclature_description)
           .with_actual(Chapter)
           .where(sections__id: id_map.keys).all do |chapter|
      if sections = id_map[chapter[:section_id]]
        sections.each do |section|
          section.associations[:chapters] << chapter
        end
      end
    end
  end)


  one_to_one :section_note

  # Tire configuration
  tire do
    index_name    'sections'
    document_type 'section'

    mapping do
      indexes :title,        analyzer: 'snowball'
    end
  end

  def to_param
    position
  end

  def to_indexed_json
    {
      id: id,
      numeral: numeral,
      title: title,
      position: position
    }.to_json
  end
end
