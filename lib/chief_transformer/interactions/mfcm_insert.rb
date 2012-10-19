require 'chief_transformer/interactions/interaction'

class ChiefTransformer
  class Processor
    class MfcmInsert < Interaction
      def process
        candidate_measures = CandidateMeasure::Collection.new([
          if record.tame.present?
            if record.tame.has_tamfs?
              record.tame.tamfs.map { |tamf|
                CandidateMeasure.new(mfcm: record,
                                     tame: record.tame,
                                     tamf: tamf,
                                     operation: :insert)
              }
            else
              [CandidateMeasure.new(mfcm: record,
                                    tame: record.tame,
                                    operation: :insert)]
            end
          end
        ].flatten.compact)
        candidate_measures.log(record)
        candidate_measures.persist
      end
    end
  end
end
