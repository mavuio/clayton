defmodule Clayton.Feedinfo do
  @moduledoc false

  @podcast_url "https://channel-clayton.uni-ak.ac.at/podcast/"
  @basedir "/www/clayton_rss/channel_clayton/episodes"

  def get_info() do
    podcast = Metalove.get_podcast(@podcast_url)
    feed = Metalove.PodcastFeed.get_by_feed_url(podcast.main_feed_url)
    _most_recent_episode = Metalove.Episode.get_by_episode_id(hd(feed.episodes))
  end

  def get_episodes() do
    podcast = Metalove.get_podcast(@podcast_url)
    feed = Metalove.PodcastFeed.get_by_feed_url(podcast.main_feed_url)

    feed.episodes
    |> Enum.map(&Metalove.Episode.get_by_episode_id(&1))

    # |> Enum.map(&generate_fixture_file(&1))
  end

  def generate_fix_script do
    data = get_fix_script_content()
    File.write!(@basedir <> "/fix_links.sh", data)
  end

  def get_fix_script_content() do
    (get_episode_urls()
     |> Enum.map(fn {num, wp_url} -> get_replacement_command(num, wp_url) end)
     |> Enum.join("\n")) <>
      "\n" <>
      (get_episodes()
       |> Enum.map(fn e ->
         n = get_episode_num(e)
         d = get_duration("#{@basedir}/episode#{n}.mp3")
         ~s(rpl '0:11:#{n}' '#{d}' _site/*.rss)
       end)
       |> Enum.join("\n"))
  end

  def get_episode_urls() do
    get_episodes()
    |> Enum.map(fn e ->
      {get_octopod_link(e), get_link(e)}
    end)
  end

  def get_octopod_link(e) do
    e.link
  end

  def get_replacement_command(o_link, wp_link) when is_binary(o_link) and is_binary(wp_link) do
    ~s(rpl '#{o_link}' '#{wp_link}' _site/*.rss)
  end

  def generate_fixture_file(e) when is_map(e) do
    data =
      e
      |> get_fixture_data()
      |> Jason.encode!()

    get_fixture_filename(e)
    |> File.write(data)

    # |> get_fixture_data()
    # |> IO.inspect(label: "mwuits-debug 2020-06-19_22:20 ")
  end

  def get_fixture_filename(e) when is_map(e) do
    num = get_episode_num(e)
    "#{@basedir}/episode#{num}.json"
  end

  def get_fixture_data(e) when is_map(e) do
    files = get_audio_files(e)
    duration = files |> hd() |> Map.get("duration")

    %{
      "version" => 5,
      "show" => %{
        "title" => "Channel Clayton—Mithören",
        "subtitle" =>
          "Wissenschaftliche Abschlussarbeiten des Instituts für Kunstwissenschaften, Kunstpädagogik und Kunstvermittlung",
        "summary" => "Channel Clayton ist auf dem Angewandte Festival 2020 als Podcast vertreten",
        "poster" => "/podcast/img/logo-itunes.jpg",
        "link" => "https://channel-clayton.uni-ak.ac.at/"
      },
      "title" => e.title,
      "subtitle" => get_subtitle(e),
      "publicationDate" => e.pub_date |> DateTime.to_iso8601(),
      "poster" => "/podcast/img/logo-itunes.jpg",
      "duration" => duration,
      "link" => get_link(e),
      "audio" => files
    }
  end

  def get_audio_files(e) when is_map(e) do
    n = get_episode_num(e)

    [
      %{"ext" => "mp3", "title" => "MP3 Audio (mp3)", "mimeType" => "audio/mpeg"},
      %{"ext" => "m4a", "title" => "MPEG-4 AAC Audio (m4a)", "mimeType" => "audio/mp4"},
      %{"ext" => "ogg", "title" => "Ogg Vorbis Audio (oga)", "mimeType" => "audio/ogg"}
    ]
    |> Enum.map(fn %{"ext" => ext} = format ->
      path = ~s(#{@basedir}/episode#{n}.#{ext})

      %{size: size} = File.stat!(path)

      format
      |> Map.put("duration", get_duration(path))
      |> Map.put("size", size)
      |> Map.put("url", "/podcast/episodes/episode#{n}.#{ext}")
      |> Map.drop(["ext"])
    end)
  end

  def get_duration(path) when is_binary(path) do
    ~s(ffmpeg -i #{path} 2>&1 | grep "Duration"| cut -d ' ' -f 4 | sed s/,//)
    |> String.to_charlist()
    |> :os.cmd()
    |> to_string()
    |> String.trim()
    |> String.replace(~r/.\d\d$/, "")
  end

  def get_subtitle(e) when is_map(e) do
    {:ok, d} = e.description |> Floki.parse_fragment()

    Floki.find(d, "p")
    |> List.first()
    |> Floki.text()

    # |> Floki.text()
  end

  def get_link(e) when is_map(e) do
    {:ok, d} = e.description |> Floki.parse_fragment()

    Floki.find(d, "a:fl-contains('zur Website')")
    |> List.first()
    # # |> if_nil("")
    |> Floki.attribute("href")
    |> hd()
  end

  def get_episode_num(e) when is_map(e) do
    Regex.run(~r/Episode (\d\d)/, e.title)
    |> List.last()
  end

  def get_episode_data(e) when is_map(e) do
    # export default {
    #   // Configuration Version
    #   version: 5,

    #   /**
    #    * Show Related Information
    #    */
    #   show: {
    #     title: "Forschergeist",
    #     subtitle: "Horizonte für Bildung und Forschung",
    #     summary:
    #       "Moderator Tim Pritlove spricht mit Wissenschaftlern und anderen Aktiven des Wissenschaftssystems \u00fcber aktuelle und zuk\u00fcnftige Trends und Praktiken f\u00fcr die Bildung, der Forschung und der Organisation und Kommunikation der Wissenschaft.\r\n\r\nDie ausf\u00fchrlichen Interviews wenden sich vor allem an junge und angehende Wissenschaftler, die nach M\u00f6glichkeiten suchen, ihre Forschung und Lehre den neuen Bed\u00fcrfnissen der Zeit anzupassen und weiter zu entwickeln.\r\n\r\nForschergeist ist ein Projekt des Stifterverbands f\u00fcr die Deutsche Wissenschaft und erscheint im Schnitt alle drei Wochen neu.",
    #     poster: "/assets/forschergeist_500x500.jpg",
    #     link: "https://forschergeist.de"
    #   },

    #   /**
    #    * Episode related Information
    #    */
    #   title: "FG072 Verantwortung in der Informatik",
    #   subtitle:
    #     "Ein Einführungskurs für Informatiker vermittelt unterschiedliche Denkweisen die gesellschaftliche Bedeutung des Fachs zu vermitteln",
    #   summary:
    #     "Informatik- ein Fach nur für Nerds? Keinesfalls, denn der Code, den Programmierer schreiben, existiert ja nicht im luftleeren Raum. Software bezieht sich letzten Endes immer auf den Menschen, interagiert mit ihm, beeinflusst das soziale Leben. Und mittlerweile ist auch an technisch gepr\u00e4gten Fakult\u00e4ten angekommen, dass Informatik eine hohe gesellschaftliche Relevanz besitzt.\r\n\r\nPeter Purgathofer lehrt an der TU Wien am Institut f\u00fcr Visual Computing. Der 56-J\u00e4hrige tritt daf\u00fcr ein, dass Software-Entwickler sich der Verantwortung bewusst sind, die ihre Arbeit hat. Denn Informatik wird zunehmend zur zentralen Disziplin schlechthin, ja sogar zum Betriebssystem unserer Gesellschaft. Tracking und Werbenetzwerke f\u00f6rdern eine Mediennutzung, bei der aufmerksamkeitsheischendes Clickbate mehr z\u00e4hlt als inhaltliche Tiefe und Seriosit\u00e4t. Automatisierte Entscheidungen k\u00f6nnen katastrophale Folgen haben, wie etwa bei t\u00f6dlichen Unf\u00e4llen autonom fahrender Autos oder den Abst\u00fcrzen der Boeing 737 Max. Algorithmen sind eben keine L\u00f6sung f\u00fcr alles, denn wie zuverl\u00e4ssig sind eigentlich die Datengrundlagen, auf denen sie aufsetzen?\r\n\r\nPurgathofer hat deshalb an seiner Hochschule einen Einf\u00fchrungskurs f\u00fcr Studienanf\u00e4nger entwickelt. Dabei geht es darum, der n\u00e4chsten Informatikergeneration fundamentales Metawissen zu vermitteln und sie damit zu bef\u00e4higen, mit einem tieferen Verst\u00e4ndnis durch ihr Studium zu navigieren: Wie sieht die Wissenschaft auf die Welt, mit welchen Denkweisen wird Wissen geschaffen? Was sind die Konsequenzen und wo liegen die Grenzen? Es wird klar: Das Leben l\u00e4sst sich nicht nur mit Einsen und Nullen erkl\u00e4ren, es entzieht sich immer wieder der Berechenbarkeit. Informatik ist eng mit Sozialwissenschaften, Philosophie und Psychologie verwoben \u2013 und Probleml\u00f6sung eben nicht nur eine technische Frage. Purgathofer kritisiert nebenbei auch die mangelnde Offenheit der vor allem unternehmensgetriebenen Forschung im Bereich K\u00fcnstlicher Intelligenz. Diese Closed Science hat f\u00fcr die Wissenschaft als Ganzes sch\u00e4dliche Effekte, die verblüffend an die Zeit der Alchimisten erinnern.",
    #   // ISO 8601 DateTime format, this is capable of adding a time offset, see https://en.wikipedia.org/wiki/ISO_8601
    #   publicationDate: "2019-10-01T11:00:44+01:00",
    #   poster: "/assets/fg072-verantwortung-in-der-informatik_500x500.jpg",
    #   // ISO 8601 Duration format ([hh]:[mm]:[ss].[sss]), capable of add ing milliseconds, see https://en.wikipedia.org/wiki/ISO_8601
    #   duration: "01:53:23.298",
    #   link:
    #     "https://forschergeist.de/podcast/fg072-verantwortung-in-der-informatik/",

    #   /**
    #    * Audio Assets
    #    * - media Assets played by the audio player
    #    * - format support depends on the used browser (https://en.wikipedia.org/wiki/HTML5_audio#Supported_audio_coding_formats)
    #    * - also supports HLS streams
    #    *
    #    * Asset
    #    * - url: absolute path to media asset
    #    * - size: file size in  byte
    #    * - (title): title to be displayed in download tab
    #    * - mimeType: media asset mimeType
    #    */
    #   audio: [
    #     {
    #       url:
    #         "https://forschergeist.de/podlove/file/2017/s/webplayer/c/episode/fg072-verantwortung-in-der-informatik.m4a",
    #       size: "71862603",
    #       title: "MPEG-4 AAC Audio (m4a)",
    #       mimeType: "audio/mp4"
    #     },
    #     {
    #       url:
    #         "https://forschergeist.de/podlove/file/2018/s/webplayer/c/episode/fg072-verantwortung-in-der-informatik.opus",
    #       size: "64346759",
    #       title: "Opus Audio (opus)",
    #       mimeType: "audio/opus"
    #     },
    #     {
    #       url:
    #         "https://forschergeist.de/podlove/file/2015/s/webplayer/c/episode/fg072-verantwortung-in-der-informatik.oga",
    #       size: "97786195",
    #       title: "Ogg Vorbis Audio (oga)",
    #       mimeType: "audio/ogg"
    #     },
    #     {
    #       url:
    #         "https://forschergeist.de/podlove/file/2014/s/webplayer/c/episode/fg072-verantwortung-in-der-informatik.mp3",
    #       size: "95522160",
    #       title: "MP3 Audio (mp3)",
    #       mimeType: "audio/mpeg"
    #     }
    #   ],

    #   /**
    #    * Files
    #    * - list of files available for download
    #    * - if no files are present, audio assets will be used as downloads
    #    *
    #    * Asset
    #    * - url: absolute path to media asset
    #    * - size: file size in  byte
    #    * - title: title to be displayed in download tab
    #    * - (mimeType): media asset mimeType
    #    */
    #   files: [
    #     {
    #       url:
    #         "https://forschergeist.de/podlove/file/2017/s/webplayer/c/episode/fg072-verantwortung-in-der-informatik.m4a",
    #       size: "71862603",
    #       title: "Episode",
    #       mimeType: "audio/mp4"
    #     },
    #     {
    #       url:
    #         "https://forschergeist.de/podlove/file/2021/s/website/c/page-footer/fg072-verantwortung-in-der-informatik.pdf",
    #       size: "284672",
    #       title: "Prospekt",
    #       mimeType: "application/pdf"
    #     },
    #     {
    #       url:
    #         "https://forschergeist.de/podlove/file/2048/s/website/c/page-footer/fg072-verantwortung-in-der-informatik.txt",
    #       size: "132090",
    #       title: "Transkripte",
    #       mimeType: "text/plain"
    #     }
    #   ],

    #   /**
    #    * Chapters:
    #    * - can be a plain list or a reference to a json file
    #    * - if present chapters tab will be available
    #    */
    #   chapters: chapters,

    #   /**
    #    * Contributors
    #    * - used by info and transcripts tab
    #    *
    #    * Contributor
    #    * - id: used as a reference in transcripts
    #    * - name: name of the contributor
    #    * - (avatar): avatar of the contributor
    #    * - (group): contributors group
    #    */
    #   contributors: [
    #     {
    #       id: "1",
    #       name: "Tim Pritlove",
    #       avatar: "/assets/tim-pritlove_150x150.jpg",
    #       group: { id: "1", slug: "onair", title: "On Air" }
    #     },
    #     {
    #       id: "77",
    #       name: "Peter Purgathofer",
    #       avatar: "/assets/peter-purgathofer_128x128.jpg",
    #       group: { id: "1", slug: "onair", title: "On Air" }
    #     }
    #   ],

    #   /**
    #    * Transcripts:
    #    * - can be a plain list or a reference to a json file
    #    * - if present transcripts tab will be available
    #    */
    #   transcripts: transcripts
    # };
  end
end
