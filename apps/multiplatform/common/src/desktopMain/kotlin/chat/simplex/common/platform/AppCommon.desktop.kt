package chat.simplex.common.platform

import chat.simplex.common.model.*
import chat.simplex.common.views.call.RcvCallInvitation
import chat.simplex.common.views.helpers.*
import java.util.*
import chat.simplex.res.MR

actual val appPlatform = AppPlatform.DESKTOP

actual val deviceName = generalGetString(MR.strings.desktop_device)

@Suppress("ConstantLocale")
val defaultLocale: Locale = Locale.getDefault()

fun initApp() {
  ntfManager = object : NtfManager() {
    override fun notifyCallInvitation(invitation: RcvCallInvitation): Boolean = chat.simplex.common.model.NtfManager.notifyCallInvitation(invitation)
    override fun hasNotificationsForChat(chatId: String): Boolean = chat.simplex.common.model.NtfManager.hasNotificationsForChat(chatId)
    override fun cancelNotificationsForChat(chatId: String) = chat.simplex.common.model.NtfManager.cancelNotificationsForChat(chatId)
    override fun displayNotification(user: UserLike, chatId: String, displayName: String, msgText: String, image: String?, actions: List<Pair<NotificationAction, () -> Unit>>) = chat.simplex.common.model.NtfManager.displayNotification(user, chatId, displayName, msgText, image, actions)
    override fun androidCreateNtfChannelsMaybeShowAlert() {}
    override fun cancelCallNotification() {}
    override fun cancelAllNotifications() = chat.simplex.common.model.NtfManager.cancelAllNotifications()
    override fun showMessage(title: String, text: String) = chat.simplex.common.model.NtfManager.showMessage(title, text)
  }
  applyAppLocale()
  if (DatabaseUtils.ksSelfDestructPassword.get() == null) {
    initChatControllerAndRunMigrations()
  }
  // LALAL
  //testCrypto()
}

fun discoverVlcLibs(path: String) {
  uk.co.caprica.vlcj.binding.LibC.INSTANCE.setenv("VLC_PLUGIN_PATH", path, 1)
}

private fun applyAppLocale() {
  val lang = ChatController.appPrefs.appLanguage.get()
  if (lang == null || lang == Locale.getDefault().language) return
  Locale.setDefault(Locale.forLanguageTag(lang))
}
