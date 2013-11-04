use 5.012003;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Mcc',
    VERSION_FROM      => 'lib/Mcc.pm',
    PREREQ_PM         => {
        "Coro"          => 0,
        "AnyEvent"      => 0,
        "String::CRC32" => 0,
        "Moo"           => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Andrey Kovbovich <akovbovich@gmail.com>') : ()),
);
