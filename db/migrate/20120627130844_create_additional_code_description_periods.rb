class CreateAdditionalCodeDescriptionPeriods < ActiveRecord::Migration
  def change
    create_table :additional_code_description_periods do |t|
      t.string :additional_code_description_period_sid
      t.string :additional_code_sid
      t.string :additional_code_type_id
      t.string :additional_code
      t.date :validity_start_date

      t.timestamps
    end
  end
end