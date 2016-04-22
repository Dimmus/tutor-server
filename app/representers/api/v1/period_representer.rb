module Api::V1
  class PeriodRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The period's id"
             }

    property :name,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The period's name"
             }

    property :enrollment_code,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               description: "The period's enrollment code"
             }

    property :default_open_time,
             type: String,
             readable: true,
             writeable: false,
             if: ->(*) { default_open_time.present? },
             getter: ->(*) { default_open_time.to_s(:time) },
             schema_info: { required: false }

    property :default_due_time,
             type: String,
             readable: true,
             writeable: false,
             if: ->(*) { default_due_time.present? },
             getter: ->(*) { default_due_time.to_s(:time) },
             schema_info: { required: false }

  end
end
