# Generated from Makefile.PL

requires 'perl', '5.6.2';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};
on 'test' => sub {
	requires 'Database::Abstraction';
	requires 'File::Temp';
	requires 'FindBin';
	requires 'IPC::System::Simple';
	requires 'Test::Carp';
	requires 'Test::DescribeMe';
	requires 'Test::HTTPStatus';
	requires 'Test::Kwalitee';
	requires 'Test::Most';
	requires 'Test::Needs';
	requires 'Test::NoWarnings';
	requires 'Test::Which';
	requires 'YAML::XS';
};
on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
