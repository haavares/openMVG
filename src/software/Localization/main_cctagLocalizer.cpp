/* 
 * File:   main_voctreeLocalizer.cpp
 * Author: sgaspari
 *
 * Created on September 12, 2015, 3:16 PM
 */
#include <openMVG/localization/VoctreeLocalizer.hpp>
#include <openMVG/localization/CCTagLocalizer.hpp>
#include <openMVG/localization/optimization.hpp>
#include <openMVG/sfm/pipelines/localization/SfM_Localizer.hpp>
#include <openMVG/image/image_io.hpp>
#include <openMVG/dataio/FeedProvider.hpp>
#include <openMVG/localization/LocalizationResult.hpp>
#include <openMVG/logger.hpp>

#include <boost/filesystem.hpp>
#include <boost/progress.hpp>
#include <boost/program_options.hpp> 
#include <boost/accumulators/accumulators.hpp>
#include <boost/accumulators/statistics/stats.hpp>
#include <boost/accumulators/statistics/mean.hpp>
#include <boost/accumulators/statistics/min.hpp>
#include <boost/accumulators/statistics/max.hpp>
#include <boost/accumulators/statistics/sum.hpp>

#include <iostream>
#include <string>
#include <chrono>

#if HAVE_ALEMBIC
#include <openMVG/sfm/AlembicExporter.hpp>
#endif // HAVE_ALEMBIC


namespace bfs = boost::filesystem;
namespace bacc = boost::accumulators;
namespace po = boost::program_options;

using namespace openMVG;

  
std::string myToString(std::size_t i, std::size_t zeroPadding)
{
  std::stringstream ss;
  ss << std::setw(zeroPadding) << std::setfill('0') << i;
  return ss.str();
}

int main(int argc, char** argv)
{
  std::string calibFile;            //< the calibration file
  std::string sfmFilePath;          //< the OpenMVG .json data file
  std::string descriptorsFolder;    //< the OpenMVG .json data file
  std::string mediaFilepath;        //< the media file to localize
  localization::CCTagLocalizer::Parameters param = localization::CCTagLocalizer::Parameters();
  std::string preset = features::describerPreset_enumToString(param._featurePreset);               //< the preset for the feature extractor
#if HAVE_ALEMBIC
  std::string exportFile = "trackedcameras.abc"; //!< the export file
#endif
  bool globalBundle = false;      //< If !param._refineIntrinsics it can run a final global budndle to refine the scene
  
  po::options_description desc(
                               "This program takes as input a media (image, image sequence, video) and a database (voctree, 3D structure data) \n"
                               "and returns for each frame a pose estimation for the camera.");
  desc.add_options()
      ("help,h", "Print this message")
      ("results,r", po::value<size_t>(&param._nNearestKeyFrames)->default_value(param._nNearestKeyFrames), "Number of images to retrieve in database")
      ("preset", po::value<std::string>(&preset)->default_value(preset), "Preset for the feature extractor when localizing a new image {LOW,NORMAL,HIGH,ULTRA}")
      ("calibration,c", po::value<std::string>(&calibFile)/*->required( )*/, "Calibration file")
      ("sfmdata,d", po::value<std::string>(&sfmFilePath)->required(), "The sfm_data.json kind of file generated by OpenMVG [it could be also a bundle.out to use an older version of OpenMVG]")
      ("siftPath,s", po::value<std::string>(&descriptorsFolder)->required(), "Folder containing the .desc [for the older version of openMVG it is the list.txt].")
      ("mediafile,m", po::value<std::string>(&mediaFilepath)->required(), "The folder path or the filename for the media to track")
      ("refineIntrinsics", po::bool_switch(&param._refineIntrinsics), "Enable/Disable camera intrinsics refinement for each localized image")
      ("globalBundle", po::bool_switch(&globalBundle), "If --refineIntrinsics is not set, this option allows to run a final global budndle adjustment to refine the scene")
      ("visualDebug", po::value<std::string>(&param._visualDebug), "If a directory is provided it enables visual debug and saves all the debugging info in that directory")
#if HAVE_ALEMBIC
      ("export,e", po::value<std::string>(&exportFile)->default_value(exportFile), "Filename for the SfM_Data export file (where camera poses will be stored). Default : trackedcameras.json If Alambic is enable it will also export an .abc file of the scene with the same name")
#endif
      ;

  po::variables_map vm;

  try
  {
    po::store(po::parse_command_line(argc, argv, desc), vm);

    if(vm.count("help") || (argc == 1))
    {
      POPART_COUT(desc);
      return EXIT_SUCCESS;
    }

    po::notify(vm);
  }
  catch(boost::program_options::required_option& e)
  {
    POPART_CERR("ERROR: " << e.what() << std::endl);
    POPART_COUT("Usage:\n\n" << desc);
    return EXIT_FAILURE;
  }
  catch(boost::program_options::error& e)
  {
    POPART_CERR("ERROR: " << e.what() << std::endl);
    POPART_COUT("Usage:\n\n" << desc);
    return EXIT_FAILURE;
  }
  if(vm.count("preset"))
  {
    param._featurePreset = features::describerPreset_stringToEnum(preset);
  }
  {
    // the bundle adjustment can be run for now only if the refine intrinsics option is not set
    globalBundle = (globalBundle && !param._refineIntrinsics);
    POPART_COUT("Program called with the following parameters:");
    POPART_COUT("\tcalibration: " << calibFile);
    POPART_COUT("\tsfmdata: " << sfmFilePath);
    POPART_COUT("\tmediafile: " << mediaFilepath);
    POPART_COUT("\tsiftPath: " << descriptorsFolder);
    POPART_COUT("\tresults: " << param._nNearestKeyFrames);
    POPART_COUT("\trefineIntrinsics: " << param._refineIntrinsics);
    POPART_COUT("\tpreset: " << features::describerPreset_enumToString(param._featurePreset));
    POPART_COUT("\tglobalBundle: " << globalBundle);
    POPART_COUT("\tvisual debug: " << param._visualDebug);
  }
  
  if(!param._visualDebug.empty() && !bfs::exists(param._visualDebug))
  {
    bfs::create_directories(param._visualDebug);
  }
 
  // init the localizer
  localization::CCTagLocalizer localizer(sfmFilePath, descriptorsFolder);

  if(!localizer.isInit())
  {
    POPART_CERR("ERROR while initializing the localizer!");
    return EXIT_FAILURE;
  }

  // create the feedProvider
  dataio::FeedProvider feed(mediaFilepath, calibFile);
  if(!feed.isInit())
  {
    POPART_CERR("ERROR while initializing the FeedProvider!");
    return EXIT_FAILURE;
  }
  bool feedIsVideo = feed.isVideo();

#if HAVE_ALEMBIC
  dataio::AlembicExporter exporter(exportFile);
  exporter.addPoints(localizer.getSfMData().GetLandmarks());
  exporter.initAnimatedCamera("camera");
#endif

  image::Image<unsigned char> imageGrey;
  cameras::Pinhole_Intrinsic_Radial_K3 queryIntrinsics;
  bool hasIntrinsics = false;

  size_t frameCounter = 0;
  size_t goodFrameCounter = 0;
  vector<string> goodFrameList;
  std::string currentImgName;

  // Define an accumulator set for computing the mean and the
  // standard deviation of the time taken for localization
  bacc::accumulator_set<double, bacc::stats<bacc::tag::mean, bacc::tag::min, bacc::tag::max, bacc::tag::sum > > stats;

  std::vector<localization::LocalizationResult> vec_localizationResults;

  while(feed.next(imageGrey, queryIntrinsics, currentImgName, hasIntrinsics))
  {
    POPART_COUT("******************************");
    POPART_COUT("FRAME " << myToString(frameCounter, 4));
    POPART_COUT("******************************");
    auto detect_start = std::chrono::steady_clock::now();
    localization::LocalizationResult localizationResult;
    localizer.localize(imageGrey,
                       &param,
                       hasIntrinsics/*useInputIntrinsics*/,
                       queryIntrinsics, // todo: put as const and use the intrinsic result store in localizationResult afterward
                       localizationResult,
                       (feedIsVideo) ? "" : currentImgName);
    auto detect_end = std::chrono::steady_clock::now();
    auto detect_elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(detect_end - detect_start);
    POPART_COUT("\nLocalization took  " << detect_elapsed.count() << " [ms]");
    stats(detect_elapsed.count());

    // save data
    if(localizationResult.isValid())
    {
#if HAVE_ALEMBIC
      //exporter.appendCamera("camera." + myToString(frameCounter, 4), localizationResult.getPose(), &queryIntrinsics, mediaFilepath, frameCounter, frameCounter);
      exporter.addCameraKeyframe(localizationResult.getPose(), &queryIntrinsics, currentImgName, frameCounter, frameCounter);
#endif
      goodFrameCounter++;
      goodFrameList.push_back(currentImgName + " : " + std::to_string(localizationResult.getIndMatch3D2D().size()) );
      
      if(globalBundle)
      {
        vec_localizationResults.emplace_back(localizationResult);
      }
    }
    else
    {
#if HAVE_ALEMBIC
      exporter.jumpKeyframe();
#endif
      POPART_CERR("Unable to localize frame " << frameCounter);
    }
    ++frameCounter;
  }

  if(globalBundle)
  {
    POPART_COUT("\n\n\n***********************************************");
    POPART_COUT("Bundle Adjustment - Refining the whole sequence");
    POPART_COUT("***********************************************\n\n");
    // run a bundle adjustment
//    const bool BAresult = localization::refineSequence(&queryIntrinsics, vec_localizationResults);
    const bool BAresult = localization::refineSequence(vec_localizationResults, true);
    if(!BAresult)
    {
      POPART_CERR("Bundle Adjustment failed!");
    }
    else
    {
#if HAVE_ALEMBIC
      // now copy back in a new abc with the same name file and BUNDLE appended at the end
      dataio::AlembicExporter exporterBA(bfs::path(exportFile).stem().string() + ".BUNDLE.abc");
      exporterBA.initAnimatedCamera("camera");
      size_t idx = 0;
      for(const localization::LocalizationResult &res : vec_localizationResults)
      {
        if(res.isValid())
        {
          assert(idx < vec_localizationResults.size());
          exporterBA.addCameraKeyframe(res.getPose(), &res.getIntrinsics(), currentImgName, frameCounter, frameCounter);
        }
        else
        {
          exporterBA.jumpKeyframe();
        }
        idx++;
      }
      exporterBA.addPoints(localizer.getSfMData().GetLandmarks());
#endif
    }
  }

  // print out some time stats
  POPART_COUT("\n\n******************************");
  POPART_COUT("Localized " << goodFrameCounter << "/" << frameCounter << " images");
  POPART_COUT("Images localized with the number of 2D/3D matches during localization :");
  for(int i = 0; i < goodFrameList.size(); i++)
    POPART_COUT(goodFrameList[i]);
  POPART_COUT("Processing took " << bacc::sum(stats)/1000 << " [s] overall");
  POPART_COUT("Mean time for localization:   " << bacc::mean(stats) << " [ms]");
  POPART_COUT("Max time for localization:   " << bacc::max(stats) << " [ms]");
  POPART_COUT("Min time for localization:   " << bacc::min(stats) << " [ms]");
}
