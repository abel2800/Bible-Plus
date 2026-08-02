package app.biblepulse.reader

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Verse of the Day + streak home-screen widget.
 * Data is written by lib/services/home_widget_service.dart.
 */
class BiblePulseWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val verseText = prefs.getString(
            "verse_text",
            "Open BiblePulse to see today's verse.",
        )
        val verseReference = prefs.getString("verse_reference", "") ?: ""
        val streak = prefs.getInt("streak", 0)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.bible_pulse_widget).apply {
                setTextViewText(R.id.widget_verse_text, verseText)
                setTextViewText(R.id.widget_reference, verseReference)
                setTextViewText(R.id.widget_streak, "Day $streak")

                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, launchIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
