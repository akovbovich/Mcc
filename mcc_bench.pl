#!perl

use strict;
use warnings;

use lib 'lib';

use Coro;
use Mcc;

use Time::HiRes 'gettimeofday';

our $Has_Cache_Memcached = eval { require Cache::Memcached; } // 0;

my $host = '127.0.0.1';
my $port = '11211';

my $_memd;
if ($Has_Cache_Memcached) {
    $_memd = Cache::Memcached->new(
        servers => ["$host:$port"],
        debug => 0,
    );
    print "Cache::Memcached found\n\n";
}

my $memd = Mcc->new(server => "$host:$port");

my $k = $ARGV[0] || 64;         # perl ./mcc_bench.pl 64
my $val = 'x' x $k;             # 64 bytes of data
my $niter = $ARGV[1] || 10_000; # perl ./mcc_bench.pl 64 10000
my @tasks;

if ($Has_Cache_Memcached) {
{
    my $t = gettimeofday;
    print "Cache::Memcached SET test started ($niter iterations/$k bytes data)\n";
    for my $n (1 .. $niter) {
        my $res = $_memd->set("key$n", $val);
    }
    my $dt = gettimeofday - $t;
    printf "Finished %d iters in %.2f seconds. Average reqs/s: %d\n", $niter, $dt, ($niter / $dt);
}{
    my $t = gettimeofday;
    print "Cache::Memcached GET test started ($niter iterations/$k bytes data)\n";
    for my $n (1 .. $niter) {
        my $res = $_memd->get("key$n");
    }
    my $dt = gettimeofday - $t;
    printf "Finished %d iters in %.2f seconds. Average reqs/s: %d\n", $niter, $dt, ($niter / $dt);
    print "\n\n";
}
} # if

for my $nthreads (1,2,4,10,100) {
my $sem = new Coro::Semaphore $nthreads; # N active threads
# ---------------------------------------
{
my $t = gettimeofday();
print "Mcc SET test started ($niter iterations/$k bytes data/$nthreads threads)\n";

for my $n (1 .. $niter) { # spawn N threads total
    push @tasks, async {
        $sem->down;
        my $res = $memd->set("key$n", $val);
        $sem->up;
    };
}

# run
$_->join for @tasks;

my $dt = gettimeofday() - $t;
printf "Finished %d iters in %.2f seconds. Average reqs/s: %d\n", $niter, $dt, ($niter / $dt);
}
# ---------------------------------------
{
my $t = gettimeofday();
print "Mcc GET test started ($niter iterations/$k bytes data/$nthreads threads)\n";

for my $n (1 .. $niter) { # spawn N threads
    push @tasks, async {
        $sem->down;
        my $res = $memd->get("key1");
        $sem->up;
    };
}

# run
$_->join for @tasks;

my $dt = gettimeofday() - $t;
printf "Finished %d iters in %.2f seconds. Average reqs/s: %d\n", $niter, $dt, ($niter / $dt);
}

print "\n\n";
} # for nthreads


