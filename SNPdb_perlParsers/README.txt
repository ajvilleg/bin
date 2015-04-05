Perl Parsers for SNPgenotype project

SNP500_FileParser.perl

- parser for allgenes.tab file from snp500cancer.nci.nih.gov website
- parses subject ID to determine population
- counts WW, WV and VV genotypes and Total for each SNP for each population
- retains SNP_ID, dbSNP_ID, Gene, Region, MajorAllele and MinorAllele information
- creates file ready to upload to SNP500_GenotypeCount table.


HapMap_FileParser.perl

- parser for the genotype_freq_* files of HapMap data available from www.hapmap.org
- parses dbSNP_ID, Population, Chromosome, Position, Strand, RefAllele, OtherAllele,
CountRefHomozygous, CountHeterozygous, CountOtherHeterozygous and CountTotal
- creates file ready for upload to HapMap_SNP_GenotypeCount table


HGDP_Michigan_ParseForGenotypes.perl

- parses datafiles for HGDP SNP data from publications by Rosenberg et al.
from http://rosenberglab.bioinformatics.med.umich.edu/diversity.html
- combines pairs of rows to create genotypes for each SNP and Individual
- separates data for different populations into different output files
to make them a more manageable size.

HGDP_Michigan_TransposeFileParser.perl

- uses output files from HGDP_Michigan_ParseForGenotypes.perl after they
have been transposed (rows and columns interchanged - using awk)
- finds first and second most common alleles for SNP (defined as reference
and other)
- counts WW, WV and VV genotypes and Total for each SNP
- retains dbSNP_ID, Population, Chromosome, Position, RefAllele and OtherAllele
- creates file ready to upload to HGDP_Michigan_GenotypeCount table.