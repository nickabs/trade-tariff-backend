require 'chief_transformer/operations/operation'

class ChiefTransformer
  class Processor
    class MfcmDelete < Operation
      def process
        Measure.with_measure_type(record.measure_type)
               .with_gono_id(record.cmdty_code)
               .valid_to(record.fe_tsmp)
               .not_terminated
               .each do |measure|
          end_date = if (measure.associated_to_non_open_ended_gono? &&
                         record.fe_tsmp > measure.goods_nomenclature_validity_end_date)
                       measure.goods_nomenclature_validity_end_date
                     else
                       record.fe_tsmp
                     end

          measure.update validity_end_date: end_date
        end
      end
    end
  end
end