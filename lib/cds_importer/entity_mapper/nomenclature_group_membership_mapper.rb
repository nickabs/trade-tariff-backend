class CdsImporter
  class EntityMapper
    class NomenclatureGroupMembershipMapper < BaseMapper
      self.entity_class = "NomenclatureGroupMembership".freeze

      self.mapping_root = "GoodsNomenclature".freeze

      self.mapping_path = "nomenclatureGroupMembership".freeze

      self.exclude_mapping = ["metainfo.origin"].freeze

      self.entity_mapping = base_mapping.merge(
        "sid" => :goods_nomenclature_sid,
        "produclineSuffix" => :productline_suffix,
        "goodsNomenclatureItemId" => :goods_nomenclature_item_id,
        "#{mapping_path}.goodsNomenclatureGroup.goodsNomenclatureGroupId" => :goods_nomenclature_group_id,
        "#{mapping_path}.goodsNomenclatureGroup.goodsNomenclatureGroupType" => :goods_nomenclature_group_type
      ).freeze

      def parse
        []
      end
    end
  end
end
