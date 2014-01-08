require 'forwardable'
java_import "java.lang.Runtime"
java_import "java.lang.management.ManagementFactory"

module Rearview
  class Vm
    extend Forwardable

    # init:
    # The initial amount of memory (bytes) that the Java virtual machine
    # requests from the operating system for memory management during startup.
    #
    # used:
    # The amount of memory currently used (bytes)
    #
    # committed:
    # represents the amount of memory (bytes) that is guaranteed to be
    # available for use by the Java virtual machine.
    #
    # max:
    # represents the maximum amount of memory (bytes) that can be used for memory
    # management
    class Memory
      extend Forwardable
      attr_accessor :memory_bean
      def_delegators :@memory_bean,:committed,:init,:max,:used
    end

    # The JVM has a heap that is the runtime memory from which all class instances
    # and arrays are allocated.
    class Heap < Memory
      def initialize
        @memory_bean = ManagementFactory.getMemoryMXBean().getHeapMemoryUsage()
      end
    end

    # The JVM manages additional memory that is not part of the heap. This memory
    # is used for things like per-class structures such as a runtime constant pool,
    # field and method data, and the code for methods and constructors.
    class NonHeap < Memory
      def initialize
        @memory_bean = ManagementFactory.getMemoryMXBean().getNonHeapMemoryUsage()
      end
    end

    def initialize
      @runtime = Runtime.getRuntime()
    end

    # total_memory:
    # The total amount of memory currently available for current and future objects (bytes)
    #
    # max_memory:
    # The maximum amount of memory that the virtual machine will attempt to use (bytes)
    #
    # free_meory:
    # An approximation to the total amount of memory currently available for future allocated objects (bytes)
    def_delegators :@runtime, :total_memory, :free_memory, :max_memory

    def heap
      @heap ||= Heap.new
    end

    def non_heap
      @non_heap ||= NonHeap.new
    end

  end
end
