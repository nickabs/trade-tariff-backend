#
# MeasureComponent is nested in to Measure.
# So we will pass @values for MeasureComponent the same as for Measure.
#

class CdsImporter
  class EntityMapper
    class MeasureComponentMapper < BaseMapper
      self.exclude_mapping = ["validityStartDate", "validityEndDate", "metainfo.origin"].freeze

      self.mapping_path = "measureComponent".freeze

      self.entity_class = "MeasureComponent".freeze

      self.entity_mapping = base_mapping.merge(
        "sid" => :measure_sid,
        "#{mapping_path}.dutyExpression.dutyExpressionId" => :duty_expression_id,
        "#{mapping_path}.dutyAmount" => :duty_amount,
        "#{mapping_path}.monetaryUnit.monetaryUnitCode" => :monetary_unit_code,
        "#{mapping_path}.measurementUnit.measurementUnitCode" => :measurement_unit_code,
        "#{mapping_path}.measurementUnitQualifier.measurementUnitQualifierCode" => :measurement_unit_qualifier_code
      ).freeze
    end
  end
end
