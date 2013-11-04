Mcc
===

Memcached Client Coro - поддерживает только текстовый протокол и асинхронные запросы.
Coro позволяет писать sequential код, тогда как запросы сами по себе не блокирующие.


Тестовое задание: сделать перловый клиент к мемкешу с двумя операциями get/set.


#### Benchmark remote host with WiFi conn (MBP 2010 2.4 Core2Duo)

##### 64 bytes

    $ perl ./mcc_bench.pl 64 100

    Cache::Memcached SET test started (100 iterations/64 bytes data)
    Finished 100 iters in 6.85 seconds. Average reqs/s: 14
    Cache::Memcached GET test started (100 iterations/64 bytes data)
    Finished 100 iters in 7.19 seconds. Average reqs/s: 13
    
    Mcc SET test started (100 iterations/64 bytes data/100 threads)
    Finished 100 iters in 0.33 seconds. Average reqs/s: 300
    Mcc GET test started (100 iterations/64 bytes data/100 threads)
    Finished 100 iters in 0.27 seconds. Average reqs/s: 375


##### 10 Kbytes

    $ perl ./mcc_bench.pl 10240 100

    Cache::Memcached SET test started (100 iterations/10240 bytes data)
    Finished 100 iters in 34.20 seconds. Average reqs/s: 2
    Cache::Memcached GET test started (100 iterations/10240 bytes data)
    Finished 100 iters in 13.69 seconds. Average reqs/s: 7
    
    Mcc SET test started (100 iterations/10240 bytes data/100 threads)
    Finished 100 iters in 45.00 seconds. Average reqs/s: 2
    Mcc GET test started (100 iterations/10240 bytes data/100 threads)
    Finished 100 iters in 1.30 seconds. Average reqs/s: 76

#### Benchmark localhost (Intel(R) Core(TM) i7 CPU 930 @ 2.80GHz):


##### 64 bytes

    $ perl ./mcc_bench.pl 64

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


Отсюда вывод, что если мемкеш сервер находится в локальной сети, то выигрышь от асинхронного клиента особенно заметен.
