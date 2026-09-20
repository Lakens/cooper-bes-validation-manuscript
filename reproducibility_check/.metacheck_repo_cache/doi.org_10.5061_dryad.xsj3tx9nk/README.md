# Araucaria bidwillii genomic data (DArTseq)

[https://doi.org/10.5061/dryad.xsj3tx9nk](https://doi.org/10.5061/dryad.xsj3tx9nk)

Unprocessed SNP dataset of Araucaria bidwillii.

## Description of the data and file structure

Data format: SNP data in 2 Rows Format. Each allele scored in a binary fashion ("1"=Presence and "0"=Absence). Heterozygotes are therefore scored as 1/1 (presence for both alleles/both rows). Missing data denoted as "-".
 

| **Metadata columns in the file:** |   |                                                                                                                                                                                                           |
| --------------------------------- | - | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **AlleleID**                      |   | Unique identifier for the sequence in which the SNP marker occurs                                                                                                                                         |
| **AlleleSequence**                |   | In 1 row format: the sequence of the Reference allele. In 2 rows format: the sequence of the Reference allele is in the Ref row, the sequence of the SNP allele in the SNP row                            |
| **AvgCountRef**                   |   | The sum of the tag read counts for all samples, divided by the number of samples with non-zero tag read counts, for the Reference allele row                                                              |
| **AvgCountSnp**                   |   | The sum of the tag read counts for all samples, divided by the number of samples with non-zero tag read counts, for the SNP allele row                                                                    |
| **AvgPIC**                        |   | The average of the polymorphism information content (PIC) of the Reference and SNP allele rows                                                                                                            |
| **CallRate**                      |   | The proportion of samples for which the genotype call is either "1" or "0", rather than "-"                                                                                                               |
| **CloneID**                       |   | Unique identifier for the sequence in which the SNP marker occurs                                                                                                                                         |
| **FreqHets**                      |   | The proportion of samples which score as heterozygous                                                                                                                                                     |
| **FreqHomRef**                    |   | The proportion of samples which score as homozygous for the Reference allele                                                                                                                              |
| **FreqHomSnp**                    |   | The proportion of samples which score as homozygous for the SNP allele                                                                                                                                    |
| **OneRatioRef**                   |   | The proportion of samples for which the genotype score is "1", in the Reference allele row                                                                                                                |
| **OneRatioSnp**                   |   | The proportion of samples for which the genotype score is "1", in the SNP allele row                                                                                                                      |
| **PICRef**                        |   | The polymorphism information content (PIC) for the Reference allele row                                                                                                                                   |
| **PICSnp**                        |   | The polymorphism information content (PIC) for the SNP allele row                                                                                                                                         |
| **RepAvg**                        |   | The proportion of technical replicate assay pairs for which the marker score is consistent                                                                                                                |
| **SNP**                           |   | In 2 rows format: this column is blank in the Reference row, and contains the base position and base variant details in the SNP row. In 1 row format: contains the base position and base variant details |
| **SnpPosition**                   |   | The position (zero indexed) in the sequence tag at which the defined SNP variant base occurs                                                                                                              |
| **TrimmedSequence**               |   | Same as the full sequence, but with removed adapters in short marker tags                                                                                                                                 |

