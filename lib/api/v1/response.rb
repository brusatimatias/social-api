module Api
  module V1
    class Response
      def self.success(data: nil, meta: {})
        new(data: data, meta: meta)
      end

      def self.error(messages, meta: {})
        new(errors: Array(messages), meta: meta)
      end

      def initialize(data: nil, errors: [], meta: {})
        @data = data
        @errors = errors
        @meta = meta
      end

      def as_json(*)
        {
          data: @data,
          errors: @errors,
          meta: @meta
        }
      end
    end
  end
end
