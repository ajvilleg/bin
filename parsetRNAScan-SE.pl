#!/usr/bin/perl

use Bio::Tools::tRNAscanSE;

sub println {
    local $\ = "\n";
    print @_;
}


sub parsetRNAScan {
	#my $tRNAfile = $ARGV[0]; #command-line argument
	my ($tRNAfile) = @_; # function call parameter
	my $gene;
	my $parser = Bio::Tools::tRNAscanSE->new(-file => $tRNAfile);
	my @trna;

	# parse the results
	while ( $gene = $parser->next_prediction() ) {
		#print $gene->get_tag_values('Codon');
		#print " ";
		#print  $gene->get_tag_values('AminoAcid');
		#print " ";
		#println $gene->start;
		push @trna, {start => $gene->start, 
				end => $gene->end, 
				strand => $gene->strand, 
				score => $gene->score, 
				id => $gene->get_tag_values('ID'),
				aminoacid => $gene->get_tag_values('AminoAcid'),
				codon => $gene->get_tag_values('Codon')};
	}

	# sort by start coordinate
	my @sorted_trna = sort {$a->{start} <=> $b->{start}} @trna;
	
	#my @sorted_trna = @trna;

	#print scalar(@sorted_trna);
	#for ($i=0; $i<scalar(@sorted_trna); $i++) {
	#	println $sorted_trna[$i]{start};
	#}
	return @sorted_trna;
}
