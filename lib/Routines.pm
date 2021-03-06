#!/usr/bin/perl -w
################################################################################
# Routine colection                                                            #
# By Roberto Torres                                                            #
################################################################################
use strict;

#################################################################################

#################################################################################
sub Progress{
    my ($n, $i, $null) = @_;
    $i++;
    my $Percentage = ($i/$n)*100;
    
    if ($i<$n){
      my $Progress = sprintf "%.3d", $Percentage;
      print "\r\tProgress: [$Progress%]";
      $|=1;
    }else{
      print "\r\tProgress: [100%]\n\n";
      $|=1;
    }
}

#################################################################################
sub Counter{
    my ($Count) = @_;
    $Count++;
    my $Counter = sprintf "%.5d", $Count;
    return $Counter;  
}

################################################################################
sub MakeDir{
    my ($NewDir) = @_;
	if (!-d "$NewDir"){
		my $cmd = `mkdir $NewDir >/dev/null 2>&1`;
	}
}

################################################################################
sub Prefix{
        my ($FileName) = @_;
        my @SplitName = split ('\.',$FileName);
        chomp @SplitName;
        my $Prefix = $SplitName[0];
        my $Ext = $SplitName[1];
        
        return $Prefix;    
}

################################################################################ 
sub SplitTab{
    my ($Row) = @_;
    my @SplitedRow = split('\t',$Row);
    chomp @SplitedRow;
    
    return @SplitedRow;
}

################################################################################
sub ReadFile{
        my ($InputFile) = @_;
        unless (open (FILE, $InputFile)){
            print "The Routine ReadFile can not open $InputFile file on $0 script\n\tExit!\n";
            exit;
            } 
        my @Temp = <FILE>;
        chomp @Temp;
        close FILE;
        my @File;
        foreach my $Row (@Temp){
               $Row =~ s/\r//g;
               if ($Row =~/^#/) {
               }else{
				push @File, $Row;     
               }
        }
        return @File;
}

#################################################################################
sub ReadSeq{
    my ($InputSeq) = @_;
    my ($Seq, @SingleFasta);
    my ($Header, @Seq) = split('\n', $InputSeq);
    chomp ($Header, @Seq);
    $Header =~ s/\n//g;
    $Header =~ s/\s//g;
    $Seq = join('',@Seq);
    $Seq =~ s/\n//g;
    $Seq =~ s/\s//g;
    $Seq =~ tr/acgt/ACGT/;
    #my @OutSeq = split('',$Seq);

    return ($Header, $Seq);
}

#################################################################################
sub ReadMultiFastaFile{
    my ($InputFile) = @_;
    
    $/=">";       

    unless (open (FILE, $InputFile)){
        print "The Routine ReadSeq can not open $InputFile file on $0 script\n\tExit!\n";
        exit;
    } 
        my $HeaderChar = <FILE>;
        my @Seq = <FILE>;
        chomp @Seq;
    close FILE;
    
    $/="\n";
    
    return @Seq;
}

################################################################################
sub ReadSeqFile{
       my ($SeqFileName) = @_;
       my ($SeqTitle, $Seq);
       my (@Seq, @DataSeq);
       unless (open (FILE, $SeqFileName)){
               print "The Routine ReadSeqFile can not open $SeqFileName file on $0 script\n\tExit!\n";
               exit;
       }
       $SeqTitle = <FILE>;
       chomp $SeqTitle;
       @Seq = <FILE>;
       chomp @Seq;
       close FILE;
       
       $Seq = join('',@Seq);
       $Seq =~ s/\n//g;
       $Seq =~ s/\s//g;
       $Seq =~ tr/acgt/ACGT/;
       
       return $Seq;
}

################################################################################
sub AnnotatedGenes{
        my ($File) = @_;
        my $cmd = `grep ">" $File`;
           $cmd =~ s/>//g;
           $cmd =~ s/\h//g;
        my @Data = split('\n',$cmd);
        return @Data;
}

################################################################################
sub GenesInBlastReport{
        my ($File, $GeneId, $null) = @_;
        open (FILE, ">>$File");

        unless (open(FILE, ">>$File")){
               print "The Routine GenesInBlastReport Can not open $File file on $0 script.\n";
               exit;
        }
               print FILE "$GeneId\n";
        close FILE;
}

################################################################################
sub DismissORFs{
        my ($Id, @IDs, $null) = @_;
        my $n = scalar@IDs;
        for(my $i=0;$i<$n;$i++){
                if($IDs[$i] eq $Id){
                        splice @IDs, $i, 1;
                        $n--;
                }
        }
        return @IDs;
}

################################################################################
sub Extract{
        my ($Qry,$DataBase,$MolType,$Entry,$OutSeq,$null) = @_;
        my $cmd = `blastdbcmd -db $DataBase -dbtype $MolType -entry "$Entry" -out $OutSeq`;
        #my $cmd = `blastdbcmd -db $DataBase -dbtype prot -entry "$Entry" -out $OutSeq`;
}

################################################################################
sub Align{
        my ($Seq1, $Seq2, $ToAlign, $AlnFile, $null) = @_;
        print "\tAligning sequences...";
        my $cmd = `cat $Seq1 $Seq2 > $ToAlign`;
        $cmd = `muscle -in $ToAlign -out $AlnFile -quiet`;
        print "Done!\n";
}

################################################################################
sub Blast{
    my ($MolType, $Qry, $Db, $Out, $e, $PIdent, $CPUs) = @_;
    if ($MolType eq "nucl"){
        my $cmd =`blastn -query $Qry -db $Db -out $Out -outfmt '6 qacc sacc length qlen slen qstart qend sstart send pident evalue bitscore' -evalue $e -max_hsps 1 -max_target_seqs 1 -qcov_hsp_perc 90 -perc_identity $PIdent -num_threads $CPUs >/dev/null 2>&1`;
    }elsif($MolType eq "prot"){
        my $cmd = `blastp -query $Qry -db $Db -out $Out -outfmt '6 qacc sacc length qlen slen qstart qend sstart send pident evalue bitscore' -evalue $e -max_hsps 1 -max_target_seqs 1 -qcov_hsp_perc 90 -num_threads $CPUs >/dev/null 2>&1`;
    }	
}

################################################################################
sub HMM{
        my ($AlnFile,$MolType,$HmmFile,$CPUs,$null) = @_;
        my $Mol;
        if ($MolType eq "nucl"){
            $Mol = "dna";
        }elsif($MolType eq "prot"){
            $Mol = "amino";
        }
        print "\tBuilding a HMM...";
        my $cmd = `hmmbuild --$Mol --cpu $CPUs $HmmFile $AlnFile`;
        print "Done!\n";
}

#################################################################################
sub Matrix{
        my ($File) = @_;
        my ($Lines, $Line, $Columns);
        my ($i);
        my (@File, @Fields, @Matrix);
        
        @File = ReadFile($File);
        $Lines = scalar@File;
        $Columns = scalar(split(",",$File[0])); 
        foreach $Line(@File){
            $Line =~ s/\r//g;
            $Line =~ s/\s//g;
            @Fields = split(",",$Line);
            push (@Matrix, [@Fields]);
        }
        
        return ($Lines, $Columns, @Matrix);
}

#################################################################################
sub Mapping{
        my ($File) = @_;
        my ($Line, $Key, $Value);
        my (@File, @Fields);
        my (%Map);
        
        @File = ReadFile($File);
        foreach $Line(@File){
            if ($Line){
                @Fields = split('\t',$Line);
                $Key = $Fields[0];
                $Value = $Fields[1];
                $Map{$Key} = $Value;
            }
        }
        
        return %Map;
}

#################################################################################
sub RGB{
    my $RGB = "#" . join "", map {sprintf "%02x", rand(255)} (0..2);
    
    return $RGB;
}

1;
