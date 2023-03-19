use strict;
use warnings;

sub file_content {
    my ($file) = @_;
    my $contents;
    open( my $fh, '<', $file ) or die "Cannot open torrent $file";
    {
        local $/;
        $contents = <$fh>;
    }
    close($fh);
    return $contents;
}

opendir(Dir, 'pieces') || die "cannot open directory\n";
my @list = readdir(Dir);
closedir(Dir);

shift(@list);
shift(@list);

my @sort_files = sort { $a <=> $b } @list;
my $data = '';

for my $file (0 .. $#sort_files) {
	my $file_piece_content = file_content( 'pieces/' . $sort_files[$file]);
	$data = $data . $file_piece_content;
}

my $file_name = "debian.iso";
open ( my $of, '>', $file_name) or die "Cannot write to $file_name";
print $of $data;
close($of);

#rmtree([ "pieces" ]);
