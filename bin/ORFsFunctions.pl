#!/usr/bin/perl -w
#################################################################################
#Scipt ORFsFunction.pl                                                          #
#                                                                               #
#Programmer:    Roberto C. Torres                                               #
#e-mail:        torres.roberto.c@gmail.com                                      #
#Date:          10 de enero de 2018                                             #
#################################################################################
use strict; 
use List::MoreUtils qw{any first_index};
use FindBin;
use lib "$FindBin::Bin/../lib";
use Routines;

my ($Usage, $ProjectName, $AnnotationPath, $MainPath, $PresenceAbsence,
    $ORFsFunctionsList, $AnnotatedTable);

$Usage = "\tUsage: ORFsFunctions.pl <Main_Path> <Project Name> <Annotation_Path> <Presence-Absence>\n";
unless(@ARGV) {
        print $Usage;
        exit;
}
chomp @ARGV;
$MainPath         = $ARGV[0];
$ProjectName      = $ARGV[1];
$AnnotationPath   = $ARGV[2];
$PresenceAbsence  = $ARGV[3];
$ORFsFunctionsList = $ARGV[4];
$AnnotatedTable   = $ARGV[5];

my ($Project, $AnnotatedPresenceAnsence, $LinesOnPresenceAbsence,
    $ColumnsOnPresenceAbsence, $ORF, $cmd, $OTU, $AnnotationFile, $Function,
    $OTUORF, $Index, $ColumnsOnAnnotation, $Gene, $ECNumber, $ORFsFunctionsFile,
    $Prefix
    );
my ($i,$j);
my (@PresenceAbsenceMatrix, @Annotation, @PresenceAbsence, @Header, @ORFData,
    @InFileName);
my $Annotated = [ ];

$Project = $MainPath ."/". $ProjectName;

@InFileName = split("/",$PresenceAbsence);
$Prefix = $InFileName[3];

$AnnotatedPresenceAnsence = $Project ."/". $ProjectName . $Prefix . "_Annotated_Presence_Absence.csv";
$ORFsFunctionsFile        = $Project ."/". $ProjectName . $Prefix . "_ORFsAnnotation.csv";

if ($ORFsFunctionsList == "1"){
        print "\nGetting the function of ORFs:";

        print "\nLoading the $PresenceAbsence file...";
        @PresenceAbsence = ReadFile($PresenceAbsence);
        $LinesOnPresenceAbsence = scalar@PresenceAbsence;
        
        @Header = split(",",$PresenceAbsence[0]);
        $ColumnsOnPresenceAbsence = scalar@Header;
        print "Done!\n";
        
        open (FILE, ">$ORFsFunctionsFile");
                print FILE "ORF,Gene,EC_Number,Product";
        close FILE;
        
        for ($i=1; $i<$LinesOnPresenceAbsence; $i++){
                @ORFData = split (",",$PresenceAbsence[$i]);
                $ORF = $ORFData[0];
                chomp$ORF;
                shift@ORFData; 
        
                $Index = first_index { $_ ne "" } @ORFData;
        
                $OTUORF = $ORFData[$Index];
                $OTU = $Header[$Index+1];
                $OTU =~s/\r//g;
                
                $AnnotationFile = $AnnotationPath ."/". $OTU ."/". $OTU . ".tsv";
        
                $cmd = `grep -w $OTUORF $AnnotationFile`;
                 
                @Annotation = split("\t",$cmd);
                $ColumnsOnAnnotation = $#Annotation;
                
                if(scalar@Annotation == 3){
                    $Gene = "";
                    $ECNumber = "";
                }elsif(scalar@Annotation == 4){
                    if ($Annotation[2] =~ /^\d/){
                        $ECNumber = $Annotation[2];
                        chomp$ECNumber;
                        $Gene = "";
                    }else{
                        $Gene     = $Annotation[2];
                        chomp$Gene;
                        $ECNumber = "";
                    }
                }elsif(scalar@Annotation == 5){
                    $Gene = $Annotation[2];
                    $ECNumber = $Annotation[3];
                }
                
                $Function = $Annotation[$#Annotation];
                chomp$Function;
                $Function =~ s/,/-/g;
                
                open (FILE, ">>$ORFsFunctionsFile");
                        print FILE "\n$ORF,$Gene,$ECNumber,$Function";
                close FILE;
                
                Progress($LinesOnPresenceAbsence, $i);
        }
}

if ($AnnotatedTable == "1"){
        ($LinesOnPresenceAbsence, $ColumnsOnPresenceAbsence, @PresenceAbsenceMatrix) = Matrix($PresenceAbsence);
        
        $Annotated -> [0][0] = $PresenceAbsenceMatrix[0]->[0];
        
        print "\nGetting annotation of each ORF:\n";
        for ($i=1; $i<$LinesOnPresenceAbsence; $i++){
           for ($j=1; $j<$ColumnsOnPresenceAbsence; $j++){
              $OTU = $PresenceAbsenceMatrix[0][$j];
              $OTU =~s/\r//g;
        
              $Annotated -> [$i][0] = $PresenceAbsenceMatrix[$i]->[0];
              $Annotated -> [0][$j] = $OTU;
              $ORF = $PresenceAbsenceMatrix[$i][$j];
              
              $AnnotationFile = $AnnotationPath ."/". $OTU ."/". $OTU . ".tsv";
             
              if ($ORF ne ""){
                 $cmd = `grep \"$ORF\tCDS\" $AnnotationFile`;
                 
                 @Annotation = split("\t",$cmd);
                 $Function = $Annotation[$#Annotation];
                 $Function =~ s/,/-/g;
                 chomp$Function;
                 $Annotated -> [$i][$j] = $Function;
        
              }else{
                 $Annotated -> [$i][$j] = "";
              }
           }
           Progress($LinesOnPresenceAbsence, $i);
        }
        
        print "\nBuilding Annotated file:\n";
        open (FILE, ">$AnnotatedPresenceAnsence");
        for ($i=0; $i<$LinesOnPresenceAbsence; $i++){
           for ($j=0; $j<$ColumnsOnPresenceAbsence; $j++){
              print FILE $Annotated -> [$i][$j], ",";
           }
           print FILE "\n";
           Progress($LinesOnPresenceAbsence, $i);
        }
        close FILE;
}
exit;