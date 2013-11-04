Mcc
===

Memcached Client Coro - поддерживает только текстовый протокол и асинхронные запросы.
Coro позволяет писать sequential код, тогда как запросы сами по себе не блокирующие.


Тестовое задание: сделать перловый клиент к мемкешу с двумя операциями get/set.



#### Benchmark (Intel(R) Core(TM) i7 CPU 930 @ 2.80GHz):


##### 64 bytes

    $ perl ./mcc_bench.pl 64`
    Cache::Memcached SET test started (10000 iterations/64 bytes data)
    Finished 10000 iters in 0.63 seconds. Average reqs/s: 15872
    Cache::Memcached GET test started (10000 iterations/64 bytes data)
    Finished 10000 iters in 1.13 seconds. Average reqs/s: 8862

    Mcc SET test started (10000 iterations/64 bytes data/4 threads)
    Finished 10000 iters in 0.79 seconds. Average reqs/s: 12706
    Mcc GET test started (10000 iterations/64 bytes data/4 threads)
    Finished 10000 iters in 1.14 seconds. Average reqs/s: 8784


##### 10 Kbytes

    $ perl ./mcc_bench.pl 10240

    Cache::Memcached SET test started (10000 iterations/10240 bytes data)
    Finished 10000 iters in 0.79 seconds. Average reqs/s: 12591
    Cache::Memcached GET test started (10000 iterations/10240 bytes data)
    Finished 10000 iters in 1.13 seconds. Average reqs/s: 8819
    
    Mcc SET test started (10000 iterations/10240 bytes data/4 threads)
    Finished 10000 iters in 0.90 seconds. Average reqs/s: 11081
    Mcc GET test started (10000 iterations/10240 bytes data/4 threads)
    Finished 10000 iters in 0.74 seconds. Average reqs/s: 13566

##### 100 Kbytes

    $ perl ./mcc_bench.pl 102400

    Cache::Memcached SET test started (10000 iterations/102400 bytes data)
    Finished 10000 iters in 1.41 seconds. Average reqs/s: 7087
    Cache::Memcached GET test started (10000 iterations/102400 bytes data)
    Finished 10000 iters in 0.79 seconds. Average reqs/s: 12681

    Mcc SET test started (10000 iterations/102400 bytes data/4 threads)
    Finished 10000 iters in 1.76 seconds. Average reqs/s: 5669
    Mcc GET test started (10000 iterations/102400 bytes data/4 threads)
    Finished 10000 iters in 0.75 seconds. Average reqs/s: 13397
