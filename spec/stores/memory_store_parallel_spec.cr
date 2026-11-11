# This spec requires `ExecutionContext`
# ameba:disable Style/NegatedConditionsInUnless
{% skip_file unless compare_versions(Crystal::VERSION, "1.20.0") >= 0 && (flag?(:execution_context) || (!flag?(:preview_mt) && !flag?(:without_mt))) %}

require "../spec_helper"
require "wait_group"

private PARALLEL_WORKERS    =    8
private PARALLEL_ITERATIONS = 2000

private def in_parallel(&block : Int32 ->)
  context = Fiber::ExecutionContext::Parallel.new("lucky-cache-spec", PARALLEL_WORKERS)
  errors = Channel(Exception).new(PARALLEL_WORKERS)
  group = WaitGroup.new(PARALLEL_WORKERS)

  PARALLEL_WORKERS.times do |worker|
    context.spawn do
      block.call(worker)
    rescue ex
      errors.send(ex)
    ensure
      group.done
    end
  end

  group.wait
  errors.close
  if error = errors.receive?
    raise error
  end
end

describe LuckyCache::MemoryStore do
  describe "parallel access" do
    it "keeps every key written from different threads" do
      cache = LuckyCache::MemoryStore.new

      in_parallel do |worker|
        PARALLEL_ITERATIONS.times do |i|
          cache.write("key:#{worker}:#{i}") { i }
        end
      end

      cache.size.should eq(PARALLEL_WORKERS * PARALLEL_ITERATIONS)
      PARALLEL_WORKERS.times do |worker|
        cache.read("key:#{worker}:#{PARALLEL_ITERATIONS - 1}").should_not be_nil
      end
    end

    it "survives mixed reads, writes, fetches, and deletes on shared keys" do
      cache = LuckyCache::MemoryStore.new

      in_parallel do |worker|
        PARALLEL_ITERATIONS.times do |i|
          key = "shared:#{i % 16}"
          case (worker + i) % 4
          when 0 then cache.write(key) { i }
          when 1 then cache.read(key)
          when 2 then cache.fetch(key, as: Int32) { i }
          else        cache.delete(key)
          end
        end
      end

      cache.size.should be <= 16
      cache.flush
      cache.size.should eq(0)
    end

    it "does not lose increments" do
      cache = LuckyCache::MemoryStore.new

      in_parallel do |_worker|
        PARALLEL_ITERATIONS.times do
          cache.increment("counter")
        end
      end

      cache.read("counter").as(LuckyCache::CacheItem).value.should eq((PARALLEL_WORKERS * PARALLEL_ITERATIONS).to_i64)
    end
  end
end
