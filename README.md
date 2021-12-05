# LedgerSync::Domains

Achieving Domain Driven Design (DDD) inside of a rails application is not a simple task. Rails engines by themself provide minimal value for code isolation. There are several gems that allows you to handle cross-engine communication through service/operation/inflection classes. Unfortunately these only touches execution, but they won't help you with passing around serialized objects.

LedgerSync has been developed to handle cross-service (API) communication in elegant way. Same aproach can be used for cross-domain communication.

Operations are great to ensure there is single point to perform specific action. If the return object is regular ActiveRecord Model object, there is nothing that stops developer from accessing cross-domain relationship, updating it or calling another action on it. You can have rubocop scanning through the code and screaming every time it finds something fishy, or you can just stop passing ActiveRecord objects around. And that is where `LedgerSync::Serializer` comes handy. It gives you simple way to define how your object should look towards specific domain. Instead of passing ruby hash(es), you work with `OpenStruct` objects that supports relationships.  

Use `LedgerSync::Operation` to trigger actions from other domains and `LedgerSync::Serializer` to pass around serialized objects instead of ActiveRecord Models. ActiveRecord Models are compatible with LedgerSync Resources and can be serialized to OpenStruct objects automatically. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ledger_sync-domains'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ledger_sync-domains

## Usage

LedgerSync comes with 3 components.
0. Registration
1. Resource
2. Serializers
3. Operations

### Register your engines

`LedgerSync::Domains` requires little configuration so it can properly pick up domains and their namespace. While `LedgerSync::Domains` is not required to be used with Rails, it is the most expected usecase. THe problem with Rails (and possibly other codebases) is that the `MainApp` does not have a module namespace and referencing it from other domain operations is not as simple. There are two methods to help you register.

#### Register your Main App

`register_main_domain` creates a domain with name `:main` without any `base_module`. This way you can reference `MainApp` as `domain: :main` and serializers/operations will be picked up from there.

```ruby
# config/application.rb
module DropBot
  class Application < Rails::Application
    LedgerSync::Domains.register_main_domain
    # ...
  end
end
```

#### Register your Engine

`register_domain` creates a domain with your own `name` and your own `base_module`. Lets say you place your engines under `engines` folder and you just created `billing` engine. To register it as a domain, update your `engine.rb` file. After that use it in your operations as `domain: :engine`. You can pass in string or symbol.
```ruby
# engines/billing/lib/billing/engine.rb
module Billing
  class Engine < ::Rails::Engine
    isolate_namespace Billing
    LedgerSync::Domains.register_domain(:billing, base_module: Billing)
  end
end
```

### Resource/Model

While `LedgerSync::Resources` represent object from external service, in case of domains we replace this with build in ActiveRecord Models. If you wish to use `LedgerSync::Domains` outside of a rails app (there is nothing that stops you doing that), just use LedgerSync::Resource to prepare your data for Serializers.

Use of ActiveRecord Models allows us to easily work with current rails data structure. Define your models as you would do in any rails application.

```ruby
class Customer < ActiveRecord::Base
  has_many :addresses
  belongs_to :user, class_name: 'Auth::User'
end

class Address < ActiveRecord::Base
  belongs_to :customer
end

module Auth
  class User < ActiveRecord::Base
    has_many :customers
  end
end
```

Alternatively you can use LedgerSync::Resource class to wrap your data into Model-like objects with relationships.
```ruby
class Customer < LedgerSync::Resource
  attribute :name, type: LedgerSync::Type::String

  references_many :addresses, to: Address
  references_one :user, to: Auth::User
end

class Address < LedgerSync::Resource
  attribute :address, type: LedgerSync::Type::String
  attribute :city, type: LedgerSync::Type::String
  attribute :country, type: LedgerSync::Type::String

  references_one :customer, to: Customer
end

module Auth
  class User < LedgerSync::Resource
    attribute :email, type: LedgerSync::Type::String

    references_many :customers, to: Customer
  end
end
```

In above example(s) you can see two models `Customer` and `Address` that are part of `Main` domain, and `User` model being part of `Auth` domain. For the sake of examples, we will have also `Client` domain that consumes both resources from `Main` as well as `Auth` domain.

### Serializers

Next step is to serialize records from these Models/Resources. One of the concepts of DDD is to be able to present your object differently to each domain. For example `User` can exposes different set of attributes towards `Client` domain as well as `Main` domain. `LedgerSync::Serializer` allows you to define serializer for each domain and specify which attributes will be exposed towards each domain.

```ruby
module Auth
  module Users
    class AuthSerializer < LedgerSync::Domains::Serializer
      attribute :email
    end
    
    class ClientSerializer < LedgerSync::Domains::Serializer
      attribute :email
    end
  end
end

module Addresses
  class ClientSerializer < LedgerSync::Domains::Serializer
    attribute :address
    attribute :city
    attribute :state
  end
end

module Customers
  class AuthSerializer < LedgerSync::Domains::Serializer
    attribute :id, resource_attribute: :ledger_id
    attribute :name
    references_one :user, resource_attribute: :user,
                          serializer: Auth::Users::AuthSerializer
  end

  class ClientSerializer < LedgerSync::Domains::Serializer
    attribute :id, resource_attribute: :ledger_id
    attribute :name
    references_many :addresses, resource_attribute: :addresses,
                                serializer: Addresses::ClientSerializer
  end
end
```

In above example we represent `Customer` with two serializers aimed towards two domains. `Customer::AuthSerializer` exposes customer and `user` relationship, while `Customer::ClientSerializer` exposes customer and `addresses` relationship.

`LedgerSync::Domains::Serializer` serializes into `OpenStruct` object. Original resource is part of it and used to lazily load and serialize relationships. This way relationships are queried and serialized only once required. Here is quick example below.


Here is quick example how that looks in above example.
```ruby
# load all above classes - watch for dependencies

irb(main):001:0> user = Auth::User.new(email: 'test@ledger_sync.dev')
=> #<Auth::User:0x00005624204f1da8 @resource_attributes=#<LedgerSync::ResourceAttributeSet:0x00005624204f1790 @attributes={:external_id=>#<L...
irb(main):002:0> customer = Customer.new(ledger_id: '123', name: 'LedgerSync', user: user)
=> #<Customer:0x0000562420792300 @resource_attributes=#<LedgerSync::ResourceAttributeSet:0x0000562420791dd8 @attributes={:external_id=>#<Led...

irb(main):003:0> auth_customer = Customers::AuthSerializer.new.serialize(resource: customer)
=> #<Customers::AuthStruct id="123", name="LedgerSync">
irb(main):004:0> auth_customer.user
=> #<Auth::Users::AuthStruct email="test@ledger_sync.dev">

irb(main):005:0> client_customer = Customers::ClientSerializer.new.serialize(resource: customer)
=> #<Customers::ClientStruct id="123", name="LedgerSync">
irb(main):006:0> client_customer.user
Traceback (most recent call last):
        3: from ./bin/console:15:in `<main>'
        2: from (irb):06:in `<main>'
        1: from /root/.asdf/installs/ruby/3.0.0/lib/ruby/3.0.0/delegate.rb:91:in `method_missing'
NoMethodError (undefined method `user' for #<OpenStruct id="123", name="LedgerSync">)
irb(main):007:0> client_customer.addresses
=> []
```
Above you can see that `client_customer` can't access `user` relationship, while `auth_customer` can.

### Operations

Operations allows you to expose actions towards other domains. Validate input based on specified contract and return result object that you can use to retrieve data or error details. Here is sample operation to fetch object by specific ID and one to deactivate an user.

```ruby
module Auth
  module Users
    class FindOperation < LedgerSync::Domains::Operation::Find
      # Ha, that was easy!
    end
  end
end

module Auth
  module Users
    class DeactivateOperation
      include LedgerSync::Domains::Operation::Mixin

      class Contract < LedgerSync::Ledgers::Contract
        params do
          required(:id).value(:integer)
        end
      end

      private

      def operate
        return failure('Not found') if resource.nil?

        if resource.update(active: false)
          success(resource)
        else
          failure('Unable to deactivate')
        end
      end

      def resource
        @resource ||= User.find_by(id: params[:id])
      end

      def failure(message)
        super(
          LedgerSync::Error::OperationError.new(
            operation: self,
            message: message
          )
        )
      end
    end
  end
end
```

Successful result of an operation should be serialized resource(s). Operations automatically perform success result serialization for you. Any `ActiveRecord::Base` or `LedgerSync::Resource` object will be automatically serialized through matching serializer for the target domain. Any other value will remain untouched. Hashes and arrays are deep-serialized, so you can return hash or array including multiple ActiveRecord objects. Operation by itself doesn't know what domain triggered it, and therefore it requires target domain to be passed either as a module, string or symbol. Here is how that looks for the example above.


```ruby
irb(main):001:0> op = Auth::Users::FindOperation.new(id: 1, limit: {}, domain: Client)
=> #<Auth::Users::FindOperation:0x0000555937876cf8 @serializer=#<Auth::Users::ClientSerializer:0x0000555937876dc0>, @deserializer=nil...
irb(main):002:0> op.perform
=> #<LedgerSync::Domains::Operation::OperationResult::Success:0x00005559372f9d70 @meta=nil, @value=#<OpenStruct email="test@ledger_sync.dev">>
irb(main):003:0> op.result.value
=> #<Auth::Users::ClientStruct email="test@ledger_sync.dev">
```

And thats it. Now you can use `LedgerSync` to define operations and have their results serialized against specific domain you are requesting it from.

#### Internal operations

Sometimes you want to create operation, that is not accessible from the rest of the app. The nature of ruby allows all defined classes be accessible from everywhere. To prevent execution of an operation from different domain, use `internal` flag when defining class.

```ruby
module Auth
  module Users
    class FindOperation < LedgerSync::Domains::Operation::Find
      internal
    end
  end
end
```

When performing an operation there are series of guards. First one validates if operation is allowed to be executed. That means either it is not flagged as internal operation, or target domain is same domain as module operation is defined in. If operation is not allowed to be executed, failure is returned with `LedgerSync::Domains::InternalOperationError` error.

### Cross-domain relationships

One important note about relationships. Splitting your app into multiple engines is eventually gonna lead to your ActiveRecord Models to have relationships that reference Models from other engines. There are two ways how to look at this issue.

#### Use of cross-domain relationships is bad

In this case, you don't define them. Or if you do, you override reader method to raise exception. If `user` references `customer`, you don't access it through `user.customer`, but you retrieve it through operation `Engine::Customers::FindOperation.new(id: user.customer_id, domain: 'OtherEngine')`. This is a clean solution, but it will lead to N+1 queries.

#### Use of cross-domain relationships is fine

If you try to get into the root of an issue, you will realize that resources reference each other is not really the source of it. The problem is that if you work with ActiveRecord objects, there is nothing stopping you from accessing related records and modifying them.

That cannot happen when accessing objects from other domains. In that case you retrieve serialized object through operation. Accessing relationships through serialized object will always return serialized relationship.

The problem is when working with records within current engine where fetching data from ActiveRecord is accepted practice. There is nothing that stops you from crossing domain boundary.

The obvious solution is to use Operations to work with Models within current engine as well. Serialized `OpenStruct` objects are (or try to be) compatible with ActiveRecord objects. They require almost zero changes in your templates. So think of them as drop-in replacement.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ledger_sync-domains.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
