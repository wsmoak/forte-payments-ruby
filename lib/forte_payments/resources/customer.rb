module FortePayments
  class Client
    module Customer

      def create_customer(options = {})
        post("/customers", options)
      end

      def list_customers(options = {})
        get("/customers", options)
      end

      def find_customer(customer_id, options = {})
        get("/customers/#{customer_id}", options)
      end

      def update_customer(customer_id, options = {})
        put("/customers/#{customer_id}", options)
      end

      def delete_customer(customer_id)
        delete("/customers/#{customer_id}")
      end

      def customer_attach_payment(customer_id, options = {})
        put("/customers/#{customer_id}/paymethods", options)
      end

      def list_transactions(customer_id)
        get("/customers/#{customer_id}/transactions")
      end
    end
  end
end
