## [Unreleased]

## [1.1.2] - 2022-04-08

- Fix: Disable previous definition warning

## [1.1.1] - 2022-03-17

- Feature: Refactor Relation into Query for use outside of relationships
- Feature: Add Query operation

## [1.1.0] - 2022-02-25

- Feature: Add and Update operations uses `data` params for setting model attributes
- Chore: minor indentation cleanup
- Feature: add method to output validation errors as a string

## [1.0.5] - 2022-02-17

- Fix: Do not serialize unset reader relational method 

## [1.0.4] - 2022-02-15

- Fix: Do not serialize unset relationships

## [1.0.3] - 2022-02-12

- Fix: Resource shorthand operations uses limit instead of query

## [1.0.2] - 2022-01-25

- Fix: Include extra query filtering in Operations
- Fix: Error return after validation falied in perform action of operation class.

## [1.0.1] - 2021-12-21

- Fix: Removing constant is private method. Sigh.

## [1.0.0] - 2021-12-20

- Chore: Cleanup existing structs when serializing

## [1.0.0.rc9] - 2021-12-19

- Fix: Cleanup serialization from predefined ActiveRecord operations

## [1.0.0.rc8] - 2021-12-19

- Fix: Temporartily disable serializing LedgerSync::Resource objects

## [1.0.0.rc7] - 2021-12-16

- Chore: Update LedgerSync to 2.3.1

## [1.0.0.rc5, 1.0.0.rc6] - 2021-12-16

- Fix: Bring back Resource to pre-defined operations

## [1.0.0.rc5] - 2021-11-05

- Add: Introduce Serializer::Relation to proxy AR Queries
- Chore: Refactor Struct out of Serializer

## [1.0.0.rc4] - 2021-09-23

- Add: Additional operations

## [1.0.0.rc3] - 2021-09-06

- Fix: Operation::Transition uses correct module name

## [1.0.0.rc2] - 2021-09-06

- Add: Serialized OpenStruct uses serializer-like class name

## [1.0.0.rc1] - 2021-08-31

- Initial release
